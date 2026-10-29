import React from 'react';
import { THEME } from '../constants';

export const HomeScreenView: React.FC<{ scrollOffset?: number }> = ({ scrollOffset = 0 }) => {
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        background: `linear-gradient(180deg, #1f3b26 0%, ${THEME.background} 32%)`,
        display: 'flex',
        flexDirection: 'column',
        fontFamily: THEME.fontFamily,
        color: THEME.textPrimary,
        position: 'relative',
      }}
    >
      {/* Top Header */}
      <div
        style={{
          padding: '16px 20px 8px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <span style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.5 }}>
          Good evening
        </span>
        <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
          {/* Bell Icon */}
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
            <path d="M13.73 21a2 2 0 0 1-3.46 0" />
          </svg>
          {/* Settings Icon */}
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="3" />
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
          </svg>
        </div>
      </div>

      {/* Scrollable Container */}
      <div
        style={{
          flex: 1,
          overflow: 'hidden',
          padding: '8px 16px',
          transform: `translateY(-${scrollOffset}px)`,
        }}
      >
        {/* Quick Access 2-Column Grid */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: 10,
            marginBottom: 24,
          }}
        >
          {[
            {
              title: 'Liked Songs',
              art: 'linear-gradient(135deg, #450af5, #c4efd9)',
              icon: '♥',
            },
            {
              title: 'Kathang Isip',
              artist: 'Ben&Ben',
              art: 'linear-gradient(135deg, #f77737, #fccc63)',
            },
            {
              title: 'Binibini',
              artist: 'Zack Tabudlo',
              art: 'linear-gradient(135deg, #5851db, #833ab4)',
            },
            {
              title: 'Downloads',
              art: 'linear-gradient(135deg, #005c2a, #1DB954)',
              icon: '↓',
            },
            {
              title: 'Deslocado',
              artist: 'NAPA',
              art: 'linear-gradient(135deg, #11998e, #38ef7d)',
            },
            {
              title: 'OPM Hits 2026',
              art: 'linear-gradient(135deg, #ff416c, #ff4b2b)',
            },
          ].map((item, i) => (
            <div
              key={i}
              style={{
                height: 52,
                background: 'rgba(255, 255, 255, 0.08)',
                borderRadius: 6,
                display: 'flex',
                alignItems: 'center',
                overflow: 'hidden',
                boxShadow: '0 4px 10px rgba(0,0,0,0.3)',
              }}
            >
              <div
                style={{
                  width: 52,
                  height: 52,
                  background: item.art,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 20,
                  color: '#ffffff',
                  fontWeight: 900,
                  flexShrink: 0,
                }}
              >
                {item.icon || ''}
              </div>
              <span
                style={{
                  padding: '0 10px',
                  fontSize: 12,
                  fontWeight: 700,
                  lineHeight: 1.2,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {item.title}
              </span>
            </div>
          ))}
        </div>

        {/* Section: Trending YouTube Music Hits */}
        <div style={{ marginBottom: 20 }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: 12,
            }}
          >
            <h3 style={{ fontSize: 18, fontWeight: 800, margin: 0 }}>
              Trending OPM & Global Hits
            </h3>
            <span style={{ fontSize: 12, color: THEME.primary, fontWeight: 700 }}>
              Show all
            </span>
          </div>

          {/* Horizontal Card Row */}
          <div style={{ display: 'flex', gap: 14 }}>
            {[
              {
                title: 'Gento',
                artist: 'SB19',
                bg: 'linear-gradient(145deg, #2b5876, #4e4376)',
              },
              {
                title: 'Raining in Manila',
                artist: 'Lola Amour',
                bg: 'linear-gradient(145deg, #000428, #004e92)',
              },
              {
                title: 'Palagi',
                artist: 'TJ Monterde',
                bg: 'linear-gradient(145deg, #e65c00, #F9D423)',
              },
            ].map((track, idx) => (
              <div
                key={idx}
                style={{
                  width: 130,
                  flexShrink: 0,
                  background: THEME.surface,
                  borderRadius: 8,
                  padding: 10,
                  display: 'flex',
                  flexDirection: 'column',
                }}
              >
                <div
                  style={{
                    width: '100%',
                    height: 110,
                    borderRadius: 6,
                    background: track.bg,
                    position: 'relative',
                    marginBottom: 8,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 6px 14px rgba(0,0,0,0.4)',
                  }}
                >
                  {/* Floating Play Button */}
                  <div
                    style={{
                      position: 'absolute',
                      right: 8,
                      bottom: 8,
                      width: 32,
                      height: 32,
                      borderRadius: 16,
                      background: THEME.primary,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      boxShadow: '0 4px 8px rgba(0,0,0,0.5)',
                    }}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="#000000">
                      <polygon points="5 3 19 12 5 21 5 3" />
                    </svg>
                  </div>
                </div>
                <span
                  style={{
                    fontSize: 13,
                    fontWeight: 700,
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {track.title}
                </span>
                <span
                  style={{
                    fontSize: 11,
                    color: THEME.textSecondary,
                    marginTop: 2,
                  }}
                >
                  {track.artist}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Floating Spotify-style Mini Player */}
      <div
        style={{
          margin: '0 10px 10px',
          height: 56,
          background: THEME.surfaceElevated,
          borderRadius: 8,
          display: 'flex',
          alignItems: 'center',
          padding: '0 12px',
          gap: 12,
          position: 'relative',
          overflow: 'hidden',
          boxShadow: '0 10px 24px rgba(0,0,0,0.6)',
        }}
      >
        {/* Top Progress Line */}
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '45%',
            height: 2,
            background: THEME.primary,
          }}
        />

        <div
          style={{
            width: 40,
            height: 40,
            borderRadius: 6,
            background: 'linear-gradient(135deg, #11998e, #38ef7d)',
            flexShrink: 0,
          }}
        />

        <div style={{ flex: 1, overflow: 'hidden' }}>
          <div
            style={{
              fontSize: 13,
              fontWeight: 700,
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
            }}
          >
            Kathang Isip
          </div>
          <div style={{ fontSize: 11, color: THEME.textSecondary }}>
            Ben&Ben • YouTube Music
          </div>
        </div>

        <svg width="18" height="18" viewBox="0 0 24 24" fill={THEME.primary}>
          <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
        </svg>

        <div
          style={{
            width: 32,
            height: 32,
            borderRadius: 16,
            background: '#ffffff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="#000000">
            <rect x="6" y="4" width="4" height="16" />
            <rect x="14" y="4" width="4" height="16" />
          </svg>
        </div>
      </div>

      {/* Bottom Navigation Bar */}
      <div
        style={{
          height: 64,
          background: THEME.background,
          borderTop: `1px solid ${THEME.divider}`,
          display: 'flex',
          justifyContent: 'space-around',
          alignItems: 'center',
          paddingBottom: 6,
        }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, color: THEME.primary }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
            <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" />
          </svg>
          <span style={{ fontSize: 11, fontWeight: 700 }}>Home</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, color: THEME.textSecondary }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <span style={{ fontSize: 11, fontWeight: 500 }}>Search</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, color: THEME.textSecondary }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
          </svg>
          <span style={{ fontSize: 11, fontWeight: 500 }}>Your Library</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, color: THEME.textSecondary }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="3" />
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
          </svg>
          <span style={{ fontSize: 11, fontWeight: 500 }}>Settings</span>
        </div>
      </div>
    </div>
  );
};
