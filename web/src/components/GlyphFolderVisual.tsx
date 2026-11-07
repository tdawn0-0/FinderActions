import React, { useEffect, useRef } from 'react';
import type { Language } from '../types';

interface GlyphFolderVisualProps {
  lang: Language;
}

const CHARS = ' .:/{}<>=#$@';
const CELL = 8;

interface CellData {
  x: number;
  y: number;
  light: number;
  role: 'accent' | 'bright' | 'muted';
  seed: number;
}

export const GlyphFolderVisual: React.FC<GlyphFolderVisualProps> = ({ lang }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const drawStepRef = useRef<((step: number) => void) | null>(null);
  const stepRef = useRef(0);
  const lastMoveRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const width = 432;
    const height = 320;
    canvas.width = width * dpr;
    canvas.height = height * dpr;

    let cancelled = false;
    const img = new Image();
    img.src = '/app-icon.png';

    img.onload = () => {
      if (cancelled) return;

      const columns = Math.floor(width / CELL);
      const rows = Math.floor(height / CELL);

      const sample = document.createElement('canvas');
      sample.width = columns;
      sample.height = rows;
      const sampler = sample.getContext('2d', { willReadFrequently: true });
      if (!sampler) return;

      const iconSize = Math.min(columns, rows) * 0.86;
      const offsetX = Math.floor((columns - iconSize) / 2);
      const offsetY = Math.floor((rows - iconSize) / 2);
      sampler.drawImage(img, offsetX, offsetY, iconSize, iconSize);
      const pixels = sampler.getImageData(0, 0, columns, rows).data;

      const makeAtlas = (color: string) => {
        const atlas = document.createElement('canvas');
        atlas.width = CELL * CHARS.length * dpr;
        atlas.height = CELL * dpr;
        const pen = atlas.getContext('2d');
        if (pen) {
          pen.scale(dpr, dpr);
          pen.font = `500 ${CELL}px ui-monospace, SFMono-Regular, Menlo, monospace`;
          pen.textAlign = 'center';
          pen.textBaseline = 'middle';
          pen.fillStyle = color;
          [...CHARS].forEach((ch, idx) => {
            pen.fillText(ch, idx * CELL + CELL / 2, CELL / 2);
          });
        }
        return atlas;
      };

      const brightAtlas = makeAtlas('#ededed');
      const mutedAtlas = makeAtlas('#85858b');
      const accentAtlas = makeAtlas('#0a84ff');

      const cells: CellData[] = [];
      for (let y = 0; y < rows; y++) {
        for (let x = 0; x < columns; x++) {
          const i = (y * columns + x) * 4;
          const r = pixels[i];
          const g = pixels[i + 1];
          const b = pixels[i + 2];
          const a = pixels[i + 3] / 255;
          if (a < 0.15) continue;

          const luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
          const isBlueFolder = b > r + 35;
          const isDarkCodeStroke = luminance < 0.38 && a > 0.5;
          const isBadgeSurface =
            !isBlueFolder &&
            luminance > 0.82 &&
            x > columns * 0.44 &&
            y > rows * 0.42 &&
            x < columns * 0.84 &&
            y < rows * 0.86;

          if (!isBlueFolder && !isDarkCodeStroke && !isBadgeSurface) continue;

          // Map dark `</>` strokes to bright high-density glyphs on a quiet dotted badge field
          const role: CellData['role'] = isDarkCodeStroke
            ? 'bright'
            : isBlueFolder
              ? 'accent'
              : 'muted';
          const light = isDarkCodeStroke
            ? 0.94
            : isBadgeSurface
              ? 0.24
              : Math.max(0.32, Math.min(0.92, (b / 255) * 0.92));

          cells.push({
            x,
            y,
            light,
            role,
            seed: (x * 73 + y * 37) % 97,
          });
        }
      }

      const draw = (step: number) => {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (const c of cells) {
          const jitter = step > 0 && Math.sin(c.seed + step * 0.6) > 0.88 ? 1 : 0;
          const idx = Math.min(
            CHARS.length - 1,
            Math.max(1, Math.floor(c.light * (CHARS.length - 1)) + jitter)
          );
          const atlas =
            c.role === 'accent'
              ? accentAtlas
              : c.role === 'bright'
                ? brightAtlas
                : mutedAtlas;
          ctx.globalAlpha =
            c.role === 'bright'
              ? 0.98
              : c.role === 'accent'
                ? 0.45 + c.light * 0.55
                : 0.36;
          ctx.drawImage(
            atlas,
            idx * CELL * dpr,
            0,
            CELL * dpr,
            CELL * dpr,
            c.x * CELL * dpr,
            c.y * CELL * dpr,
            CELL * dpr,
            CELL * dpr
          );
        }
        ctx.globalAlpha = 1;
      };

      drawStepRef.current = draw;
      draw(0);
    };

    return () => {
      cancelled = true;
      drawStepRef.current = null;
    };
  }, []);

  const handlePointerMove = () => {
    const now = performance.now();
    if (now - lastMoveRef.current < 120) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    lastMoveRef.current = now;
    stepRef.current += 1;
    drawStepRef.current?.(stepRef.current);
  };

  const labels =
    lang === 'zh'
      ? { top: '"$@" 参数数组', right: 'FA_CWD 工作目录', bottom: 'exit 0 → 通知' }
      : { top: '"$@" argv paths', right: 'FA_CWD directory', bottom: 'exit 0 → notify' };

  return (
    <div
      onPointerMove={handlePointerMove}
      className="relative w-[432px] max-w-full h-[320px] mx-auto flex items-center justify-center select-none"
      aria-hidden="true"
    >
      <canvas ref={canvasRef} className="w-[432px] h-[320px] max-w-full" />

      <svg
        viewBox="0 0 432 320"
        className="hidden sm:block absolute inset-0 w-full h-full pointer-events-none"
      >
        {/* Top-left leader to folder tab */}
        <line x1="126" y1="36" x2="156" y2="68" stroke="rgba(237,237,237,0.22)" strokeWidth="1" />
        <rect x="153" y="65" width="6" height="6" rx="1" fill="#141415" stroke="#0a84ff" strokeWidth="1.5" />

        {/* Right leader to folder body */}
        <line x1="336" y1="68" x2="306" y2="96" stroke="rgba(237,237,237,0.22)" strokeWidth="1" />
        <rect x="303" y="93" width="6" height="6" rx="1" fill="#141415" stroke="#0a84ff" strokeWidth="1.5" />

        {/* Bottom-right leader to </> script badge */}
        <line x1="312" y1="278" x2="282" y2="236" stroke="rgba(237,237,237,0.22)" strokeWidth="1" />
        <rect x="279" y="233" width="6" height="6" rx="1" fill="#141415" stroke="#ededed" strokeWidth="1.5" />
      </svg>

      <div className="hidden sm:inline-flex items-center px-2.5 h-6 rounded-[6px] bg-[#19191b] border border-[#ededed]/12 text-[12px] leading-[16px] font-mono text-[#ededed] absolute top-3 left-4">
        {labels.top}
      </div>

      <div className="hidden sm:inline-flex items-center px-2.5 h-6 rounded-[6px] bg-[#19191b] border border-[#ededed]/12 text-[12px] leading-[16px] font-mono text-[#ededed] absolute top-11 right-2">
        {labels.right}
      </div>

      <div className="hidden sm:inline-flex items-center px-2.5 h-6 rounded-[6px] bg-[#19191b] border border-[#ededed]/12 text-[12px] leading-[16px] font-mono text-[#4cc38a] absolute bottom-4 right-6">
        {labels.bottom}
      </div>
    </div>
  );
};
