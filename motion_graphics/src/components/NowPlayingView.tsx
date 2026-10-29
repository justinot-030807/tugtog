import React from 'react';
import { THEME } from '../constants';

export const NowPlayingView: React.FC<{ progress?: number; wavePhase?: number }> = ({
  progress = 0.52,
  wavePhase = 0,
}) => {
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        background: `linear-gradient(180deg, #164024 0%, #102117 40%, ${THEME.background} 90%)`,
        display: 'flex',
        flexDirection: 'column',
        fontFamily: THEME.fontFamily,
        color: THEME.textPrimary,
        padding: '16px 24px',
        boxSizing: 'border-box',
        position: 'relative',
      }}
    >
      {/* Top Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 24,
        }}
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
          <polyline points="6 9 12 15 18 9" />
        </svg>

        <div style={{ textAlign: 'center' }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              letterSpacing: 1.5,
              color: THEME.textSecondary,
              textTransform: 'uppercase',
            }}
          >
            Playing from YouTube Music
          </div>
          <div style={{ fontSize: 12, fontWeight: 700, color: '#ffffff', marginTop: 2 }}>
            YouTube Music (Online)
          </div>
        </div>

        <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
          <circle cx="12" cy="12" r="2" />
          <circle cx="12" cy="5" r="2" />
          <circle cx="12" cy="19" r="2" />
        </svg>
      </div>

      {/* Album Artwork with Neon Glow */}
      <div
        style={{
          width: '100%',
          aspectRatio: '1/1',
          borderRadius: 16,
          background: 'linear-gradient(135deg, #f77737 0%, #fccc63 50%, #1DB954 100%)',
          boxShadow: `0 24px 50px rgba(0,0,0,0.8), 0 0 40px ${THEME.primary}44`,
          marginBottom: 24,
          position: 'relative',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {/* Subtle Vinyl Texture Pattern */}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'radial-gradient(circle, transparent 30%, rgba(0,0,0,0.3) 70%)',
          }}
        />

        {/* Dancing Audio Equalizer Bars Inside Artwork */}
        <div
          style={{
            position: 'absolute',
            bottom: 16,
            right: 16,
            display: 'flex',
            gap: 3,
            alignItems: 'flex-end',
            height: 24,
            padding: '6px 8px',
            background: 'rgba(0,0,0,0.6)',
            borderRadius: 8,
            backdropFilter: 'blur(8px)',
          }}
        >
          {[0.8, 0.4, 1.0, 0.6, 0.9].map((h, i) => {
            const dynamicHeight = Math.abs(Math.sin(wavePhase + i * 0.8)) * 16 + 4;
            return (
              <div
                key={i}
                style={{
                  width: 3,
                  height: dynamicHeight,
                  background: THEME.primary,
                  borderRadius: 1.5,
                }}
              />
            );
          })}
        </div>
      </div>

      {/* Track Info & Like Button */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 16,
        }}
      >
        <div>
          <div style={{ fontSize: 20, fontWeight: 800, letterSpacing: -0.5 }}>
            Kathang Isip
          </div>
          <div style={{ fontSize: 14, color: THEME.textSecondary, marginTop: 4 }}>
            Ben&Ben
          </div>
        </div>

        <svg width="24" height="24" viewBox="0 0 24 24" fill={THEME.primary}>
          <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
        </svg>
      </div>

      {/* Progress Bar & Durations */}
      <div style={{ marginBottom: 16 }}>
        <div
          style={{
            height: 4,
            background: 'rgba(255,255,255,0.2)',
            borderRadius: 2,
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          <div
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: `${progress * 100}%`,
              height: '100%',
              background: '#ffffff',
            }}
          />
        </div>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            fontSize: 11,
            color: THEME.textSecondary,
            marginTop: 6,
          }}
        >
          <span>2:45</span>
          <span>5:18</span>
        </div>
      </div>

      {/* Player Controls */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 20,
        }}
      >
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={THEME.primary} strokeWidth="2.5">
          <polyline points="16 3 21 3 21 8" />
          <line x1="4" y1="20" x2="21" y2="3" />
          <polyline points="21 16 21 21 16 21" />
          <line x1="15" y1="15" x2="21" y2="21" />
          <line x1="4" y1="4" x2="9" y2="9" />
        </svg>

        <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor">
          <polygon points="19 20 9 12 19 4 19 20" />
          <line x1="5" y1="19" x2="5" y2="5" stroke="currentColor" strokeWidth="2" />
        </svg>

        {/* Big White Circular Play/Pause Button */}
        <div
          style={{
            width: 64,
            height: 64,
            borderRadius: 32,
            background: '#ffffff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 8px 24px rgba(255,255,255,0.25)',
          }}
        >
          <svg width="22" height="22" viewBox="0 0 24 24" fill="#000000">
            <rect x="6" y="4" width="4" height="16" />
            <rect x="14" y="4" width="4" height="16" />
          </svg>
        </div>

        <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor">
          <polygon points="5 4 15 12 5 20 5 4" />
          <line x1="19" y1="5" x2="19" y2="19" stroke="currentColor" strokeWidth="2" />
        </svg>

        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={THEME.textSecondary} strokeWidth="2">
          <polyline points="17 1 21 5 17 9" />
          <path d="M3 11V9a4 4 0 0 1 4-4h14" />
          <polyline points="7 23 3 19 7 15" />
          <path d="M21 13v2a4 4 0 0 1-4 4H3" />
        </svg>
      </div>

      {/* Extra Bottom Icons: Sleep Timer, Equalizer, Queue */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '0 8px',
          color: THEME.textSecondary,
        }}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
        </svg>

        <div style={{ display: 'flex', gap: 4, alignItems: 'center', color: THEME.primary, fontSize: 12, fontWeight: 700 }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <rect x="4" y="10" width="3" height="10" />
            <rect x="10.5" y="4" width="3" height="16" />
            <rect x="17" y="7" width="3" height="13" />
          </svg>
          <span>Equalizer Active</span>
        </div>

        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <line x1="8" y1="6" x2="21" y2="6" />
          <line x1="8" y1="12" x2="21" y2="12" />
          <line x1="8" y1="18" x2="21" y2="18" />
          <line x1="3" y1="6" x2="3.01" y2="6" />
          <line x1="3" y1="12" x2="3.01" y2="12" />
          <line x1="3" y1="18" x2="3.01" y2="18" />
        </svg>
      </div>
    </div>
  );
};
