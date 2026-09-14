from fastapi import APIRouter

router = APIRouter(tags=["Offline Sync"])

@router.get("/sync/manifest")
def get_sync_manifest(since: str = "0"):
    return {
        "manifestVersion": "1.0",
        "packs": [
            {
                "id": "pack_grade1_lang",
                "grade": 1,
                "subject": "language",
                "contentHash": "sha256_ab123ff",
                "sizeBytes": 2048500,
            },
            {
                "id": "pack_grade1_math",
                "grade": 1,
                "subject": "math",
                "contentHash": "sha256_bc456ff",
                "sizeBytes": 1820100,
            }
        ]
    }

@router.get("/sync/pack/{pack_id}")
def get_sync_pack(pack_id: str):
    return {
        "packId": pack_id,
        "status": "ready",
        "downloadUrl": f"/static/packs/{pack_id}.bin"
    }
