import React from 'react';
import { Sequence, useCurrentFrame, useVideoConfig } from 'remotion';
import { Scene1Hook } from './scenes/Scene1Hook';
import { Scene2Home } from './scenes/Scene2Home';
import { Scene3Search } from './scenes/Scene3Search';
import { Scene4NowPlaying } from './scenes/Scene4NowPlaying';
import { Scene5Offline } from './scenes/Scene5Offline';
import { Scene6Outro } from './scenes/Scene6Outro';

export const TugtogPromo: React.FC = () => {
  return (
    <div
      style={{
        flex: 1,
        backgroundColor: '#090909',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {/* Scene 1: The Hook (0 - 5s / frames 0 - 150) */}
      <Sequence from={0} durationInFrames={150}>
        <Scene1Hook />
      </Sequence>

      {/* Scene 2: Home Screen UI Reveal (5s - 11s / frames 150 - 330) */}
      <Sequence from={150} durationInFrames={180}>
        <Scene2Home />
      </Sequence>

      {/* Scene 3: Search & Music Catalog (11s - 17s / frames 330 - 510) */}
      <Sequence from={330} durationInFrames={180}>
        <Scene3Search />
      </Sequence>

      {/* Scene 4: Now Playing Studio Experience (17s - 23s / frames 510 - 690) */}
      <Sequence from={510} durationInFrames={180}>
        <Scene4NowPlaying />
      </Sequence>

      {/* Scene 5: Offline Mode & Zero Ads (23s - 29s / frames 690 - 870) */}
      <Sequence from={690} durationInFrames={180}>
        <Scene5Offline />
      </Sequence>

      {/* Scene 6: Outro & Call to Action (29s - 35s / frames 870 - 1050) */}
      <Sequence from={870} durationInFrames={180}>
        <Scene6Outro />
      </Sequence>
    </div>
  );
};
