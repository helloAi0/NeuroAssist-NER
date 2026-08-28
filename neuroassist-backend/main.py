import os
import json
from typing import List
from collections import defaultdict

from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from google import genai

import models
import schemas
from database import engine, get_db

app = FastAPI(title="NeuroAssist API")

# Enable CORS for mobile device connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_KEY = os.environ.get(
    "GEMINI_API_KEY", 
    "AQ.Ab8RN6JIHSO4IW_1A104mnppEr_2msAzkBL63Lo4IPAs0cg5mA"
)

client = genai.Client(api_key=API_KEY)

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(models.Base.metadata.create_all)

@app.get("/api/summary")
async def get_ai_summary(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.SyncEvent)
        .order_by(models.SyncEvent.id.desc())
        .limit(10)
    )
    db_events = result.scalars().all()
    
    if not db_events:
        return {"summary": "No activity data available yet. Please complete some tasks on the mobile app and sync them!"}
    
    recent_events = [
        {
            "event_type": event.event_type, 
            "payload": event.payload, 
            "time_synced": str(event.synced_at)
        } 
        for event in db_events
    ]
    
    prompt = f"""
    You are an encouraging and professional medical AI assistant. 
    Review the following recent patient activity events and write a short, 
    comforting 2-sentence summary for their family member or caregiver. 
    Keep the tone optimistic but grounded.
    Events data: {recent_events}
    """
    
    try:
        response = await client.aio.models.generate_content(
            model='gemini-1.5-flash',
            contents=prompt
        )
        return {"summary": response.text.strip()}
    except Exception as e:
        print(f"\n[GEMINI ERROR LOG]: {e}\n")
        return {"summary": f"AI Error: {str(e)}"}

@app.post("/api/sync", response_model=schemas.SyncBatchResponse)
async def sync_events(
    batch: schemas.SyncBatchRequest, 
    background_tasks: BackgroundTasks, 
    db: AsyncSession = Depends(get_db)
):
    synced_count = 0
    
    for event_data in batch.events:
        e_id = str(event_data.id or event_data.event_id or "")
        e_type = str(event_data.type or event_data.event_type or "unknown")
        
        e_payload = event_data.payload
        if isinstance(e_payload, (dict, list)):
            e_payload = json.dumps(e_payload)
        elif not isinstance(e_payload, str):
            e_payload = str(e_payload)
            
        result = await db.execute(
            select(models.SyncEvent).filter(models.SyncEvent.event_id == e_id)
        )
        existing_event = result.scalars().first()
        
        if not existing_event:
            new_event = models.SyncEvent(
                event_id=e_id,
                event_type=e_type,
                payload=e_payload
            )
            db.add(new_event)
            synced_count += 1
            
    await db.commit()
    
    # Fire the anomaly evaluation in the background AFTER committing to DB
    background_tasks.add_task(evaluate_performance_drop, batch.events)
    
    return {"status": "success", "synced_count": synced_count}

async def evaluate_performance_drop(events_list: List[schemas.SyncEventRequest]):
    """
    Background task to scan newly synced events for cognitive anomalies.
    """
    for event_data in events_list:
        e_type = str(event_data.type or event_data.event_type or "unknown")
        payload = event_data.payload
        
        # Parse payload safely
        if isinstance(payload, str):
            try:
                payload = json.loads(payload)
            except:
                continue
                
        # Define alert triggers based on game type
        if e_type == 'memory_match':
            score = payload.get('score', 100)
            errors = payload.get('errors', 0)
            
            # Simulated Alert Condition: Score under 50 OR more than 5 errors
            if score < 50 or errors > 5:
                print(f"\n[CRITICAL ALERT TRIGGERED] Cognitive score drop detected!")
                print(f"Event ID: {event_data.id} | Score: {score} | Errors: {errors}")
                print(f"Action: Dispatching push notification to caregiver's device...\n")
                
        elif e_type == 'reaction_time':
            avg_ms = payload.get('average_ms', 0)
            if avg_ms > 1500:
                print(f"\n[WARNING ALERT] Severe reaction time delay detected ({avg_ms}ms).")

@app.get("/api/analytics/trends")
async def get_analytics_trends(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.SyncEvent)
        .order_by(models.SyncEvent.synced_at.asc())
    )
    events = result.scalars().all()

    daily_stats = defaultdict(lambda: {"total_score": 0, "total_errors": 0, "session_count": 0})

    for event in events:
        date_key = event.synced_at.strftime("%Y-%m-%d")
        
        payload = event.payload if isinstance(event.payload, dict) else json.loads(event.payload)
        
        score = payload.get("score", 0)
        errors = payload.get("errors", 0)

        daily_stats[date_key]["total_score"] += score
        daily_stats[date_key]["total_errors"] += errors
        daily_stats[date_key]["session_count"] += 1

    trends_response = []
    for date_str, stats in daily_stats.items():
        trends_response.append({
            "date": date_str,
            "avg_score": round(stats["total_score"] / stats["session_count"], 1),
            "avg_errors": round(stats["total_errors"] / stats["session_count"], 1),
            "total_sessions": stats["session_count"]
        })

    return {"trends": trends_response}

@app.get("/api/ai/insights")
async def get_predictive_insights(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.SyncEvent)
        .order_by(models.SyncEvent.synced_at.asc())
    )
    events = result.scalars().all()

    if len(events) < 5:
        return {"insight": "More data needed. Continue playing daily modules to unlock predictive insights."}

    historical_data = []
    for event in events:
        payload = event.payload if isinstance(event.payload, dict) else json.loads(event.payload)
        historical_data.append({
            "date": event.synced_at.strftime("%Y-%m-%d %H:%M"),
            "type": event.event_type,
            "metrics": payload
        })

    prompt = f"""
    You are an expert neurological data scientist analyzing a patient's cognitive game performance.
    Analyze this time-series data and provide a concise, 3-paragraph predictive report.
    
    1. Identify any multi-day trends (e.g., improving memory, degrading reaction time).
    2. Check for time-of-day correlations (e.g., higher errors in the evening).
    3. Suggest a specific focus for tomorrow's session based on the weakest metrics.
    
    Data: {json.dumps(historical_data)}
    """
    
    try:
        response = await client.aio.models.generate_content(
            model='gemini-1.5-flash',
            contents=prompt
        )
        return {"insight": response.text.strip()}
    except Exception as e:
        print(f"\n[AI INSIGHT ERROR]: {e}\n")
        return {"insight": "Unable to generate insights at this time."}

@app.get("/api/events")
async def get_all_events(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.SyncEvent))
    events = result.scalars().all()
    return events