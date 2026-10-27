# Tugtog YouTube Music Companion Backend

A lightweight FastAPI companion microservice that interfaces with YouTube Music via [`ytmusicapi`](https://github.com/sigma67/ytmusicapi) to retrieve your personal read-only playback history and perform searches for the Tugtog Flutter music player.

---

## Features
- **`GET /health`**: Returns backend server status and checks whether `browser.json` is configured.
- **`GET /history`**: Returns your recently played tracks from YouTube Music (`videoId`, `title`, `artists`, `album`, `thumbnail`, `duration`, `played`).
- **`GET /search?q=`**: Searches songs on YouTube Music and formats them into the identical JSON shape.
- **CORS enabled**: Supports cross-origin requests from Flutter Android (emulator `10.0.2.2`, local LAN IP, or Web).
- **Session expiry handling**: Returns clear, actionable HTTP 401 error messages when authentication headers expire.

---

## Setup & Installation

### 1. Prerequisites
- Python 3.8 or higher installed on your computer.

### 2. Create Virtual Environment & Install Dependencies
From the root of the project, navigate into the `backend/` directory:

```bash
cd backend
python -m venv venv
```

Activate the virtual environment:
- **Windows (PowerShell):**
  ```powershell
  .\venv\Scripts\Activate.ps1
  ```
- **Windows (Command Prompt):**
  ```cmd
  .\venv\Scripts\activate.bat
  ```
- **macOS / Linux:**
  ```bash
  source venv/bin/activate
  ```

Install dependencies:
```bash
pip install -r requirements.txt
```

---

## Generating `browser.json` (Authentication)

YouTube Music requires browser session headers to read your private account history. Follow these exact steps:

1. **Open YouTube Music in your browser:**
   - Open Chrome, Edge, or Firefox.
   - Navigate to [https://music.youtube.com](https://music.youtube.com) and ensure you are logged into your Google account.

2. **Open Developer Tools:**
   - Press `F12` (or `Ctrl+Shift+I` / `Cmd+Option+I`) to open Developer Tools.
   - Click on the **Network** tab.
   - Type `browse` in the filter box.

3. **Find an authenticated request:**
   - Click around YouTube Music (e.g., click on "Home" or "Library" or play a track) until network requests appear.
   - Look for a `POST` request to `browse` (e.g., `https://music.youtube.com/youtubei/v1/browse?...`).
   - Click on it, then view the **Headers** tab.
   - Scroll down to the **Request Headers** section.

4. **Run `ytmusicapi browser`:**
   In your terminal (with the virtual environment active inside `backend/`):
   ```bash
   ytmusicapi browser
   ```
   - When prompted: `Paste request headers and press Enter twice:`
   - Select and copy all text under **Request Headers** from DevTools.
   - Paste it into the terminal prompt.
   - Press `Enter` twice.
   - `ytmusicapi` will parse and save your authentication headers into `browser.json` in the current directory (`backend/browser.json`).

> [!NOTE]
> `backend/browser.json` contains your personal session cookies and is automatically excluded from git tracking in `.gitignore`. **Never commit or share your `browser.json` file.**

---

## Running the Server

Start the FastAPI server:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API will now be running at:
- **Local Machine:** [http://localhost:8000](http://localhost:8000)
- **Interactive Swagger Docs:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Android Emulator Access:** `http://10.0.2.2:8000`

---

## API Endpoints

### 1. Health Check
```http
GET /health
```
**Response:**
```json
{
  "status": "ok",
  "authenticated": true,
  "auth_file": "browser.json",
  "auth_file_present": true
}
```

---

### 2. Playback History
```http
GET /history
```
**Response:**
```json
[
  {
    "videoId": "dQw4w9WgXcQ",
    "title": "Never Gonna Give You Up",
    "artists": "Rick Astley",
    "album": "Whenever You Need Somebody",
    "thumbnail": "https://lh3.googleusercontent.com/...",
    "duration": "3:33",
    "played": "Today"
  }
]
```

---

### 3. Song Search
```http
GET /search?q=daft+punk
```
**Response:**
```json
[
  {
    "videoId": "5NV6Rdv1a3I",
    "title": "Get Lucky",
    "artists": "Daft Punk, Pharrell Williams",
    "album": "Random Access Memories",
    "thumbnail": "https://lh3.googleusercontent.com/...",
    "duration": "4:08",
    "played": null
  }
]
```

---

## Troubleshooting & Expired Sessions

If `GET /history` returns `401 Unauthorized`:
```json
{
  "detail": "YouTube Music rejected authentication: ... Your session cookies likely expired."
}
```
Google session cookies expire periodically or when you log out. Simply repeat the **Generating browser.json** steps above to copy fresh headers and replace `backend/browser.json`.
