import React from 'react';
import { THEME } from '../constants';

export const SearchScreenView: React.FC<{ query?: string; typingProgress?: number }> = ({
  query = 'Ben&Ben',
  typingProgress = 1,
}) => {
  const currentChars = Math.floor(query.length * Math.min(1, Math.max(0, typingProgress)));
  const displayedText = query.substring(0, currentChars);

  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        background: THEME.background,
        display: 'flex',
        flexDirection: 'column',
        fontFamily: THEME.fontFamily,
        color: THEME.textPrimary,
        padding: '16px 20px',
        boxSizing: 'border-box',
      }}
    >
      <h2 style={{ fontSize: 26, fontWeight: 800, margin: '0 0 16px 0', letterSpacing: -0.5 }}>
        Search
      </h2>

      {/* Spotify White Search Input Bar */}
      <div
        style={{
          height: 48,
          background: '#ffffff',
          borderRadius: 8,
          display: 'flex',
          alignItems: 'center',
          padding: '0 14px',
          gap: 10,
          boxShadow: '0 8px 20px rgba(0,0,0,0.4)',
          marginBottom: 20,
        }}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000000" strokeWidth="2.5">
          <circle cx="11" cy="11" r="8" />
          <line x1="21" y1="21" x2="16.65" y2="16.65" />
        </svg>
        <span
          style={{
            fontSize: 15,
            fontWeight: 600,
            color: '#121212',
            letterSpacing: -0.2,
          }}
        >
          {displayedText || 'What do you want to listen to?'}
          {typingProgress < 1 && (
            <span
              style={{
                display: 'inline-block',
                width: 2,
                height: 16,
                background: THEME.primary,
                marginLeft: 2,
                verticalAlign: 'middle',
              }}
            />
          )}
        </span>
      </div>

      {/* Multi-Catalog Results Group */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* Group 1: YouTube Music (No Ads) */}
        <div
          style={{
            background: THEME.surface,
            borderRadius: 12,
            padding: 12,
            border: '1px solid rgba(255,255,255,0.06)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <div
              style={{
                width: 24,
                height: 24,
                borderRadius: 12,
                background: '#ff0000',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill="#ffffff">
                <polygon points="5 3 19 12 5 21 5 3" />
              </svg>
            </div>
            <span style={{ fontSize: 13, fontWeight: 800, color: '#ffffff' }}>
              YouTube Music (No Ads)
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 46,
                height: 46,
                borderRadius: 6,
                background: 'linear-gradient(135deg, #f77737, #fccc63)',
                flexShrink: 0,
              }}
            />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>Kathang Isip</div>
              <div style={{ fontSize: 12, color: THEME.textSecondary }}>Ben&Ben • 5:18</div>
            </div>
            <div
              style={{
                background: 'rgba(29, 185, 84, 0.15)',
                color: THEME.primary,
                fontSize: 11,
                fontWeight: 700,
                padding: '4px 8px',
                borderRadius: 12,
              }}
            >
              Stream
            </div>
          </div>
        </div>

        {/* Group 2: On your phone (Local Storage) */}
        <div
          style={{
            background: THEME.surface,
            borderRadius: 12,
            padding: 12,
            border: '1px solid rgba(255,255,255,0.06)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <div
              style={{
                width: 24,
                height: 24,
                borderRadius: 12,
                background: THEME.primary,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#000000" strokeWidth="2">
                <rect x="5" y="2" width="14" height="20" rx="2" ry="2" />
                <line x1="12" y1="18" x2="12.01" y2="18" />
              </svg>
            </div>
            <span style={{ fontSize: 13, fontWeight: 800, color: '#ffffff' }}>
              On your phone (Local Storage)
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 46,
                height: 46,
                borderRadius: 6,
                background: 'linear-gradient(135deg, #11998e, #38ef7d)',
                flexShrink: 0,
              }}
            />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>Leaves</div>
              <div style={{ fontSize: 12, color: THEME.textSecondary }}>Ben&Ben • Audio File</div>
            </div>
            <div
              style={{
                background: 'rgba(255, 255, 255, 0.1)',
                color: '#ffffff',
                fontSize: 11,
                fontWeight: 700,
                padding: '4px 8px',
                borderRadius: 12,
              }}
            >
              Offline
            </div>
          </div>
        </div>

        {/* Group 3: Audius & Jamendo */}
        <div
          style={{
            background: THEME.surface,
            borderRadius: 12,
            padding: 12,
            border: '1px solid rgba(255,255,255,0.06)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <div
              style={{
                width: 24,
                height: 24,
                borderRadius: 12,
                background: '#cc00ff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill="#ffffff">
                <circle cx="12" cy="12" r="10" />
                <polygon points="10 8 16 12 10 16 10 8" />
              </svg>
            </div>
            <span style={{ fontSize: 13, fontWeight: 800, color: '#ffffff' }}>
              Audius & Jamendo (Indie)
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 46,
                height: 46,
                borderRadius: 6,
                background: 'linear-gradient(135deg, #8a2387, #e94057, #f27121)',
                flexShrink: 0,
              }}
            />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>Kathang Isip (Acoustic Cover)</div>
              <div style={{ fontSize: 12, color: THEME.textSecondary }}>Acoustic Sessions • 4:45</div>
            </div>
            <div
              style={{
                background: 'rgba(204, 0, 255, 0.15)',
                color: '#e066ff',
                fontSize: 11,
                fontWeight: 700,
                padding: '4px 8px',
                borderRadius: 12,
              }}
            >
              Free
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
