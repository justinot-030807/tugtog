import React from 'react';
import { Composition } from 'remotion';
import { TugtogPromo } from './TugtogPromo';
import { VIDEO_CONFIG } from './constants';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* 9:16 Vertical Video (TikTok, Reels, Shorts) */}
      <Composition
        id="TugtogPromoReel"
        component={TugtogPromo}
        durationInFrames={VIDEO_CONFIG.durationInFrames}
        fps={VIDEO_CONFIG.fps}
        width={1080}
        height={1920}
      />

      {/* 16:9 Landscape Video (YouTube, Facebook, Desktop) */}
      <Composition
        id="TugtogPromoLandscape"
        component={TugtogPromo}
        durationInFrames={VIDEO_CONFIG.durationInFrames}
        fps={VIDEO_CONFIG.fps}
        width={1920}
        height={1080}
      />
    </>
  );
};
