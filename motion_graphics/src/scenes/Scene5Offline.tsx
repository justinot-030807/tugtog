import React from 'react';
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { THEME } from '../constants';
import { PhoneMockup } from '../components/PhoneMockup';
import { NowPlayingView } from '../components/NowPlayingView';

export const Scene5Offline: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const phoneEntrance = spring({
    frame,
    fps,
    config: { damping: 14, mass: 0.8 },
  });

  const cards = [
    {
      title: '100% Ad-Free Forever',
      desc: 'Walang video ads, walang popups, tuloy-tuloy ang tugtog.',
      icon: '⚡',
      color: '#ffbb00',
      delay: 15,
    },
    {
      title: 'Auto-Offline Cache',
      desc: 'Kahit mawalan ng internet o data, playable pa rin.',
      icon: '💾',
      color: THEME.primary,
      delay: 35,
    },
    {
      title: 'Background & Lock Screen',
      desc: 'Kahit patay ang screen, may notification player controls.',
      icon: '📱',
      color: '#00d2ff',
      delay: 55,
    },
    {
      title: '5-Band Equalizer & Dolby Atmos',
      desc: 'Custom audio curves, Bass Boost, at direct Xiaomi / Mi Sound Enhancer integration.',
      icon: '🎛️',
      color: THEME.primary,
      delay: 75,
    },
  ];

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
        padding: '0 30px',
        boxSizing: 'border-box',
      }}
    >
      {/* Background Accent Glow */}
      <div
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          width: 700,
          height: 700,
          borderRadius: 350,
          background: `radial-gradient(circle, ${THEME.primary}20 0%, #00d2ff18 50%, transparent 70%)`,
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
          Premium Features. Zero Cost.
        </span>
        <h2
          style={{
            fontSize: 42,
            fontWeight: 950,
            color: '#ffffff',
            margin: '6px 0 0',
            letterSpacing: -1,
          }}
        >
          Spotify Vibes. No Monthly Fee.
        </h2>
      </div>

      {/* Feature Cards Grid Over Center */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 16,
          width: '100%',
          maxWidth: 520,
          zIndex: 30,
          marginTop: 100,
        }}
      >
        {cards.map((card, i) => {
          const cardSpring = spring({
            frame: frame - card.delay,
            fps,
            config: { damping: 12, mass: 0.6 },
          });

          const opacity = interpolate(frame, [card.delay, card.delay + 10], [0, 1], {
            extrapolateLeft: 'clamp',
            extrapolateRight: 'clamp',
          });

          return (
            <div
              key={i}
              style={{
                transform: `translateX(${interpolate(cardSpring, [0, 1], [60, 0])}px) scale(${cardSpring})`,
                opacity,
                background: 'rgba(24, 24, 24, 0.85)',
                backdropFilter: 'blur(16px)',
                border: '1px solid rgba(255, 255, 255, 0.1)',
                borderRadius: 16,
                padding: '16px 20px',
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                boxShadow: `0 12px 30px rgba(0,0,0,0.6), 0 0 20px ${card.color}22`,
              }}
            >
              <div
                style={{
                  width: 52,
                  height: 52,
                  borderRadius: 26,
                  background: `${card.color}22`,
                  border: `1.5px solid ${card.color}66`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 24,
                  flexShrink: 0,
                }}
              >
                {card.icon}
              </div>
              <div style={{ flex: 1 }}>
                <h4
                  style={{
                    fontSize: 18,
                    fontWeight: 800,
                    color: '#ffffff',
                    margin: 0,
                    letterSpacing: -0.3,
                  }}
                >
                  {card.title}
                </h4>
                <p
                  style={{
                    fontSize: 13,
                    color: THEME.textSecondary,
                    margin: '4px 0 0',
                    lineHeight: 1.3,
                  }}
                >
                  {card.desc}
                </p>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
