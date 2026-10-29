import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { THEME } from '../constants';
import { PhoneMockup } from '../components/PhoneMockup';
import { HomeScreenView } from '../components/HomeScreenView';

export const Scene2Home: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const phoneEntrance = spring({
    frame,
    fps,
    config: { damping: 14, mass: 0.8 },
  });

  const scrollProgress = interpolate(frame, [30, 90], [0, 80], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const rotY = interpolate(frame, [0, 60, 120], [-18, 0, 8]);
  const rotX = interpolate(frame, [0, 60, 120], [12, 4, 8]);

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
          top: '25%',
          left: '50%',
          width: 600,
          height: 600,
          borderRadius: 300,
          background: `radial-gradient(circle, ${THEME.primary}28 0%, transparent 70%)`,
          filter: 'blur(80px)',
          transform: 'translate(-50%, -50%)',
        }}
      />

      {/* Floating Header Badge */}
      <div
        style={{
          position: 'absolute',
          top: 80,
          textAlign: 'center',
          zIndex: 40,
          opacity: interpolate(frame, [0, 20], [0, 1]),
          transform: `translateY(${interpolate(frame, [0, 20], [-20, 0])}px)`,
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
          Spotify-Inspired Clean UI
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
          Familiar. Fast. Beautiful.
        </h2>
      </div>

      {/* 3D Smartphone Device Mockup */}
      <div
        style={{
          marginTop: 60,
          transform: `scale(${phoneEntrance})`,
        }}
      >
        <PhoneMockup
          rotationX={rotX}
          rotationY={rotY}
          glowColor={THEME.primary}
        >
          <HomeScreenView scrollOffset={scrollProgress} />
        </PhoneMockup>
      </div>
    </div>
  );
};
