import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { THEME } from '../constants';

export const Scene6Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const entrance = spring({
    frame,
    fps,
    config: { damping: 12, mass: 0.6 },
  });

  const pulse = Math.sin(frame * 0.15) * 6;

  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        background: '#090909',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: THEME.fontFamily,
        position: 'relative',
        overflow: 'hidden',
        textAlign: 'center',
        padding: '0 40px',
        boxSizing: 'border-box',
      }}
    >
      {/* Background Pulsing Sonic Rings */}
      {[250, 400, 580].map((size, idx) => {
        const ringScale = 1 + ((frame * 0.02 + idx * 0.3) % 1);
        const ringOpacity = (1 - ((frame * 0.02 + idx * 0.3) % 1)) * 0.35;
        return (
          <div
            key={idx}
            style={{
              position: 'absolute',
              width: size,
              height: size,
              borderRadius: size / 2,
              border: `2px solid ${THEME.primary}`,
              opacity: ringOpacity,
              transform: `scale(${ringScale})`,
              pointerEvents: 'none',
            }}
          />
        );
      })}

      <div
        style={{
          transform: `scale(${entrance})`,
          zIndex: 10,
        }}
      >
        {/* Tugtog Logo App Icon */}
        <div
          style={{
            width: 120,
            height: 120,
            borderRadius: 36,
            background: `linear-gradient(145deg, #1f3b26, #121212)`,
            border: `3px solid ${THEME.primary}`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            margin: '0 auto 24px',
            boxShadow: `0 20px 50px rgba(0,0,0,0.8), 0 0 60px ${THEME.primary}66`,
            transform: `translateY(${pulse}px)`,
          }}
        >
          {/* Vinyl / Waveform Icon */}
          <svg width="64" height="64" viewBox="0 0 24 24" fill={THEME.primary}>
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 14.5c-2.49 0-4.5-2.01-4.5-4.5S9.51 7.5 12 7.5s4.5 2.01 4.5 4.5-2.01 4.5-4.5 4.5zm0-5.5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1z" />
          </svg>
        </div>

        <h1
          style={{
            fontSize: 72,
            fontWeight: 950,
            color: '#ffffff',
            letterSpacing: -2,
            margin: 0,
          }}
        >
          Tugtog
        </h1>

        <p
          style={{
            fontSize: 22,
            color: THEME.textSecondary,
            margin: '12px 0 28px',
            fontWeight: 500,
          }}
        >
          Ang Musika Mo. Walang Ads. Walang Harang.
        </p>

        {/* Call to Action Button */}
        <div
          style={{
            background: THEME.primary,
            color: '#000000',
            padding: '16px 36px',
            borderRadius: 36,
            fontSize: 20,
            fontWeight: 900,
            letterSpacing: -0.3,
            display: 'inline-flex',
            alignItems: 'center',
            gap: 12,
            boxShadow: '0 10px 30px rgba(29, 185, 84, 0.4)',
          }}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#000000" strokeWidth="2.5">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
            <polyline points="7 10 12 15 17 10" />
            <line x1="12" y1="15" x2="12" y2="3" />
          </svg>
          <span>I-download ang APK (v1.0.0)</span>
        </div>

        <div
          style={{
            marginTop: 20,
            fontSize: 13,
            color: THEME.textSecondary,
            fontWeight: 600,
          }}
        >
          Free & Open-Source • Android 10+ Supported
        </div>
      </div>
    </div>
  );
};
