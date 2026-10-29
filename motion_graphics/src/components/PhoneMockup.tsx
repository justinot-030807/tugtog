import React from 'react';
import { THEME } from '../constants';

interface PhoneMockupProps {
  children: React.ReactNode;
  scale?: number;
  rotationX?: number;
  rotationY?: number;
  rotationZ?: number;
  glowColor?: string;
}

export const PhoneMockup: React.FC<PhoneMockupProps> = ({
  children,
  scale = 1,
  rotationX = 0,
  rotationY = 0,
  rotationZ = 0,
  glowColor = THEME.primary,
}) => {
  return (
    <div
      style={{
        transform: `scale(${scale}) rotateX(${rotationX}deg) rotateY(${rotationY}deg) rotateZ(${rotationZ}deg)`,
        transformStyle: 'preserve-3d',
        transition: 'transform 0.1s ease-out',
        width: 440,
        height: 900,
        borderRadius: 54,
        background: '#0a0a0a',
        padding: 14,
        boxShadow: `0 35px 80px rgba(0,0,0,0.85), 0 0 60px ${glowColor}33, inset 0 0 0 2px #333333, inset 0 0 0 4px #1a1a1a`,
        position: 'relative',
        display: 'flex',
        flexDirection: 'column',
        boxSizing: 'border-box',
      }}
    >
      {/* Outer Phone Border Highlights */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          borderRadius: 54,
          border: '1px solid rgba(255, 255, 255, 0.15)',
          pointerEvents: 'none',
        }}
      />

      {/* Screen Frame */}
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: 42,
          background: THEME.background,
          overflow: 'hidden',
          position: 'relative',
          display: 'flex',
          flexDirection: 'column',
          boxSizing: 'border-box',
        }}
      >
        {/* Android / Dynamic Island Status Bar */}
        <div
          style={{
            height: 44,
            padding: '0 24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: 'transparent',
            zIndex: 50,
            fontSize: 13,
            fontWeight: 600,
            color: '#ffffff',
            letterSpacing: -0.2,
          }}
        >
          <span>9:41</span>
          {/* Camera Notch */}
          <div
            style={{
              width: 90,
              height: 22,
              background: '#000000',
              borderRadius: 12,
              position: 'relative',
            }}
          />
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span style={{ fontSize: 11, color: THEME.textSecondary }}>5G</span>
            <div
              style={{
                width: 20,
                height: 10,
                border: '1px solid #ffffff',
                borderRadius: 3,
                padding: 1,
              }}
            >
              <div
                style={{
                  width: '85%',
                  height: '100%',
                  background: THEME.primary,
                  borderRadius: 1.5,
                }}
              />
            </div>
          </div>
        </div>

        {/* Inner Screen Content */}
        <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
          {children}
        </div>

        {/* Android Home Navigation Bar Indicator */}
        <div
          style={{
            height: 20,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: THEME.background,
          }}
        >
          <div
            style={{
              width: 120,
              height: 4,
              borderRadius: 2,
              background: 'rgba(255,255,255,0.4)',
            }}
          />
        </div>
      </div>
    </div>
  );
};
