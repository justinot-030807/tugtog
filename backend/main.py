import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from fastapi import FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from ytmusicapi import YTMusic
from ytmusicapi.exceptions import YTMusicError

app = FastAPI(
    title="Tugtog YT Music Companion Backend",
    description="Local companion API providing YouTube Music history and search for the Tugtog music player.",
    version="1.0.0",
)

# Enable CORS for Flutter app (Android emulator 10.0.2.2, physical devices, localhost)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BROWSER_AUTH_FILE = Path(__file__).resolve().parent / "browser.json"


def get_ytmusic(require_auth: bool = True) -> YTMusic:
    """
    Initializes and returns a YTMusic client instance.
    Checks for presence of browser.json when authentication is required.
    """
    if not BROWSER_AUTH_FILE.exists():
        if require_auth:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=(
                    "Authentication file 'browser.json' is missing. "
                    "Please follow backend/README.md instructions using 'ytmusicapi browser' "
                    "to generate your browser.json authentication file."
                ),
            )
        # Fallback to unauthenticated client for public search
        return YTMusic()

    try:
        return YTMusic(str(BROWSER_AUTH_FILE))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                f"Failed to load YTMusic authentication headers from browser.json: {exc}. "
                "Please regenerate browser.json following backend/README.md."
            ),
        )


def _format_track(item: Dict[str, Any], default_played: Optional[str] = None) -> Dict[str, Any]:
    """
    Normalizes a ytmusicapi song or history item to a consistent JSON structure.
    """
    # Extract artists string
    artists_raw = item.get("artists")
    if isinstance(artists_raw, list):
        artist_names = [a.get("name") for a in artists_raw if isinstance(a, dict) and a.get("name")]
        artists = ", ".join(artist_names) if artist_names else "Unknown Artist"
    elif isinstance(artists_raw, str):
        artists = artists_raw
    else:
        artists = "Unknown Artist"

    # Extract album title
    album_raw = item.get("album")
    if isinstance(album_raw, dict):
        album = album_raw.get("name")
    elif isinstance(album_raw, str):
        album = album_raw
    else:
        album = None

    # Pick highest resolution thumbnail
    thumbnails = item.get("thumbnails") or []
    thumbnail_url = thumbnails[-1].get("url") if thumbnails else None

    # Fix relative or protocol-relative thumbnail URLs
    if thumbnail_url and thumbnail_url.startswith("//"):
        thumbnail_url = "https:" + thumbnail_url

    return {
        "videoId": item.get("videoId") or item.get("id"),
        "title": item.get("title") or "Unknown Title",
        "artists": artists,
        "album": album,
        "thumbnail": thumbnail_url,
        "duration": item.get("duration"),
        "played": item.get("played") or default_played,
    }


@app.get("/health", summary="Health check")
def health() -> Dict[str, Any]:
    """Check API server health and authentication state."""
    auth_exists = BROWSER_AUTH_FILE.exists()
    return {
        "status": "ok",
        "authenticated": auth_exists,
        "auth_file": str(BROWSER_AUTH_FILE.name),
        "auth_file_present": auth_exists,
    }


@app.get("/history", summary="Recently played tracks from YouTube Music")
def get_history() -> List[Dict[str, Any]]:
    """
    Retrieves read-only playback history from the user's YouTube Music account.
    Requires backend/browser.json with valid cookie/header credentials.
    """
    yt = get_ytmusic(require_auth=True)
    try:
        history_raw = yt.get_history()
    except YTMusicError as err:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                f"YouTube Music rejected authentication: {err}. "
                "Your session cookies likely expired. Please re-run 'ytmusicapi browser' "
                "to update browser.json with fresh headers."
            ),
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An unexpected error occurred while fetching history: {exc}",
        )

    tracks: List[Dict[str, Any]] = []
    for item in history_raw:
        # get_history() items include videoId, title, artists, album, thumbnails, duration, played
        formatted = _format_track(item)
        if formatted["videoId"]:
            tracks.append(formatted)

    return tracks


@app.get("/search", summary="Search songs on YouTube Music")
def search_songs(q: str = Query(..., min_length=1, description="Search query string")) -> List[Dict[str, Any]]:
    """
    Searches for songs on YouTube Music and formats results into the unified JSON shape.
    Works with browser.json auth if present, or unauthenticated as fallback.
    """
    yt = get_ytmusic(require_auth=False)
    try:
        search_results = yt.search(query=q, filter="songs")
    except YTMusicError as err:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"YouTube Music search error: {err}",
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unexpected error searching songs: {exc}",
        )

    tracks: List[Dict[str, Any]] = []
    for item in search_results:
        formatted = _format_track(item)
        if formatted["videoId"]:
            tracks.append(formatted)

    return tracks


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
