from pydantic import BaseModel
from typing import List, Any, Optional, Union

class SyncEventRequest(BaseModel):
    # Accepts either 'id' or 'event_id', as integer or string
    id: Optional[Union[str, int]] = None
    event_id: Optional[Union[str, int]] = None
    
    # Accepts either 'type' or 'event_type'
    type: Optional[str] = None
    event_type: Optional[str] = None
    
    # Accepts dictionaries, lists, strings, or primitive types
    payload: Any = {}

class SyncBatchRequest(BaseModel):
    events: List[SyncEventRequest]

class SyncBatchResponse(BaseModel):
    status: str
    synced_count: int