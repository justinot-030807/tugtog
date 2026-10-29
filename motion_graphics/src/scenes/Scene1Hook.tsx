import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { THEME } from '../constants';

export const Scene1Hook: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const entrance = spring({
    frame,
    fps,
    config: { damping: 12, mass: 0.5 },
  });

  const glitch = Math.sin(frame * 0.8) * (frame < 45 ? 6 : 0);
  const textOpacity = interpolate(frame, [0, 15, 60, 75], [0, 1, 1, 0]);

  const introEntrance = spring({
    frame: frame - 70,
    fps,
    config: { damping: 10, mass: 0.6 },
  });

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
        padding: '0 40px',
        boxSizing: 'border-box',
      }}
    >
      {/* Background Ambient Glow */}
      <div
        style={{
          position: 'absolute',
          width: 500,
          height: 500,
          borderRadius: 250,
          background: `radial-gradient(circle, ${THEME.primary}22 0%, transparent 70%)`,
          filter: 'blur(60px)',
          transform: `scale(${1 + Math.sin(frame * 0.1) * 0.1})`,
        }}
      />

      {/* Part 1: Pain point text (Frames 0 - 75) */}
      {frame < 75 && (
        <div
          style={{
            opacity: textOpacity,
            transform: `translateY(${glitch}px) scale(${entrance})`,
            textAlign: 'center',
            zIndex: 10,
          }}
        >
          {/* Ad Block Icon */}
          <div
            style={{
              width: 80,
              height: 80,
              borderRadius: 40,
              background: 'rgba(255, 68, 68, 0.15)',
              border: '2px solid rgba(255, 68, 68, 0.4)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 24px',
            }}
          >
            <span style={{ fontSize: 36, color: '#ff4444' }}>✕</span>
          </div>

          <h1
            style={{
              fontSize: 54,
              fontWeight: 900,
              color: '#ffffff',
              lineHeight: 1.15,
              letterSpacing: -1.5,
              margin: 0,
            }}
          >
            Sawang-sawa ka na ba <br />
            sa <span style={{ color: '#ff4444', textDecoration: 'line-through' }}>ADS</span> habang nagpapatugtog?
          </h1>
          <p
            style={{
              fontSize: 22,
              color: THEME.textSecondary,
              marginTop: 18,
              fontWeight: 500,
            }}
          >
            Pati background playback at downloads may bayad?
          </p>
        </div>
      )}

      {/* Part 2: The Solution Announcement (Frames 75+) */}
      {frame >= 70 && (
        <div
          style={{
            transform: `scale(${introEntrance})`,
            opacity: interpolate(frame, [70, 85], [0, 1]),
            textAlign: 'center',
            zIndex: 10,
          }}
        >
          <span
            style={{
              fontSize: 18,
              fontWeight: 800,
              color: THEME.primary,
              letterSpacing: 4,
              textTransform: 'uppercase',
            }}
          >
            Oras na para mag-upgrade
          </span>
          <h2
            style={{
              fontSize: 72,
              fontWeight: 950,
              color: '#ffffff',
              margin: '12px 0 0',
              letterSpacing: -2,
            }}
          >
            Meet <span style={{ color: THEME.primary }}>Tugtog</span>
          </h2>
          <div
            style={{
              display: 'inline-block',
              background: 'rgba(29, 185, 84, 0.15)',
              border: `1px solid ${THEME.primary}66`,
              padding: '8px 24px',
              borderRadius: 30,
              color: '#ffffff',
              fontSize: 18,
              fontWeight: 700,
              marginTop: 20,
            }}
          >
            The Ultimate Ad-Free Music Player
          </div>
        </div>
      )}
    </div>
  );
};
