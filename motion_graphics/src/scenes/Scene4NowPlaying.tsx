import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { THEME } from '../constants';
import { PhoneMockup } from '../components/PhoneMockup';
import { NowPlayingView } from '../components/NowPlayingView';

export const Scene4NowPlaying: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const entrance = spring({
    frame,
    fps,
    config: { damping: 14, mass: 0.8 },
  });

  const zoomScale = interpolate(frame, [0, 80], [1, 1.08]);
  const progress = interpolate(frame, [0, 150], [0.45, 0.65]);
  const wavePhase = frame * 0.25;

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
      {/* Dynamic Ambient Background Glow Synced with Album Art */}
      <div
        style={{
          position: 'absolute',
          top: '35%',
          left: '50%',
          width: 700,
          height: 700,
          borderRadius: 350,
          background: `radial-gradient(circle, #f7773733 0%, ${THEME.primary}33 50%, transparent 75%)`,
          filter: 'blur(100px)',
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
            color: THEME.primary,
            letterSpacing: 2,
            textTransform: 'uppercase',
          }}
        >
          Studio-Quality Sound
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
          Lossless Stream & Built-in EQ
        </h2>
      </div>

      <div
        style={{
          marginTop: 60,
          transform: `scale(${entrance * zoomScale})`,
        }}
      >
        <PhoneMockup
          rotationX={2}
          rotationY={Math.sin(frame * 0.05) * 4}
          glowColor={THEME.primary}
        >
          <NowPlayingView progress={progress} wavePhase={wavePhase} />
        </PhoneMockup>
      </div>
    </div>
  );
};
