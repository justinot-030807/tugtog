import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { THEME } from '../constants';
import { PhoneMockup } from '../components/PhoneMockup';
import { SearchScreenView } from '../components/SearchScreenView';

export const Scene3Search: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const entrance = spring({
    frame,
    fps,
    config: { damping: 15, mass: 0.7 },
  });

  const typingProgress = interpolate(frame, [15, 55], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const rotY = interpolate(frame, [0, 60, 120], [8, -5, 0]);

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
      }}
    >
      {/* Background Accent Glow */}
      <div
        style={{
          position: 'absolute',
          top: '30%',
          left: '50%',
          width: 650,
          height: 650,
          borderRadius: 325,
          background: `radial-gradient(circle, #cc00ff22 0%, ${THEME.primary}22 50%, transparent 70%)`,
          filter: 'blur(90px)',
          transform: 'translate(-50%, -50%)',
        }}
      />

      {/* Floating Header */}
      <div
        style={{
          position: 'absolute',
          top: 80,
          textAlign: 'center',
          zIndex: 40,
          opacity: interpolate(frame, [0, 15], [0, 1]),
        }}
      >
        <span
          style={{
            fontSize: 14,
            fontWeight: 800,
            color: '#cc00ff',
            letterSpacing: 2,
            textTransform: 'uppercase',
          }}
        >
          All-In-One Unified Search
        </span>
        <h2
          style={{
            fontSize: 38,
            fontWeight: 900,
            color: '#ffffff',
            margin: '6px 0 0',
            letterSpacing: -0.5,
          }}
        >
          Lahat ng Kanta. Walang Kulang.
        </h2>
      </div>

      <div
        style={{
          marginTop: 60,
          transform: `scale(${entrance})`,
        }}
      >
        <PhoneMockup
          rotationX={4}
          rotationY={rotY}
          glowColor="#cc00ff"
        >
          <SearchScreenView query="Ben&Ben - Kathang Isip" typingProgress={typingProgress} />
        </PhoneMockup>
      </div>
    </div>
  );
};
