from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from database import Base

class SyncEvent(Base):
    __tablename__ = "sync_events"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(String, unique=True, index=True)
    event_type = Column(String, index=True)
    payload = Column(String)
    synced_at = Column(DateTime, default=datetime.utcnow)