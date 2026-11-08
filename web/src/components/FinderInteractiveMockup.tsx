import React, { useState, useRef, useEffect } from 'react';
import {
  Folder,
  FileText,
  FileCode,
  Image as ImageIcon,
  Terminal,
  Code2,
  Copy,
  Archive,
  ChevronLeft,
  ChevronRight,
  Clock,
  FileCheck2,
  Layers,
  Hammer,
  Wifi,
  Search,
} from 'lucide-react';
import { AppleLogo } from './Navbar';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FinderInteractiveMockupProps {
  lang: Language;
}

interface FileItem {
  id: string;
  name: string;
  size: string;
  type: string;
  iconType: 'image' | 'json' | 'sh' | 'pdf' | 'folder';
  matched: string[];
}

const FILES: FileItem[] = [
  { id: '1', name: 'hero-banner.png', size: '1.4 MB', type: 'PNG Image', iconType: 'image', matched: ['copy-path', 'copy-name', 'convert-webp', 'compress'] },
  { id: '2', name: 'api-schema.json', size: '18 KB', type: 'JSON', iconType: 'json', matched: ['open-vscode', 'copy-path', 'format-json', 'compress'] },
  { id: '3', name: 'deploy-pipeline.sh', size: '3.2 KB', type: 'Shell Script', iconType: 'sh', matched: ['open-terminal', 'open-vscode', 'copy-path', 'copy-name'] },
  { id: '4', name: 'design-spec.pdf', size: '4.8 MB', type: 'PDF Document', iconType: 'pdf', matched: ['copy-path', 'copy-name', 'compress'] },
  { id: '5', name: 'build-artifacts', size: '12 items', type: 'Folder', iconType: 'folder', matched: ['open-terminal', 'open-vscode', 'copy-path', 'compress'] },
];

const SCREEN_W = 1440;
const SCREEN_H = 900;
const INNER_RATIO = 0.8524;

export const FinderInteractiveMockup: React.FC<FinderInteractiveMockupProps> = ({ lang }) => {
  const t = translations[lang].demo;

  const [selectedFile, setSelectedFile] = useState<FileItem>(FILES[0]);
  const [menuOpen, setMenuOpen] = useState(true);
  const [menuPosition, setMenuPosition] = useState({ x: 480, y: 230 });
  const [toastKey, setToastKey] = useState<keyof typeof t.toastFeedback | null>(null);
  const [wrapWidth, setWrapWidth] = useState(1008);
  const wrapRef = useRef<HTMLDivElement>(null);
  const desktopRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const update = () => {
      if (el.clientWidth > 0) setWrapWidth(el.clientWidth);
    };
    update();
    const ro = new ResizeObserver(update);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const scale = (wrapWidth * INNER_RATIO) / SCREEN_W;

  const openMenuForItem = (file: FileItem, clientX?: number, clientY?: number) => {
    setSelectedFile(file);
    if (desktopRef.current && clientX !== undefined && clientY !== undefined) {
      const rect = desktopRef.current.getBoundingClientRect();
      const logicX = (clientX - rect.left) / scale;
      const logicY = (clientY - rect.top) / scale;
      const clickX = Math.min(Math.max(logicX, 240), SCREEN_W - 340);
      const clickY = Math.min(Math.max(logicY, 120), SCREEN_H - 340);
      setMenuPosition({ x: clickX, y: clickY });
    } else {
      const rowIdx = FILES.findIndex((item) => item.id === file.id);
      setMenuPosition({ x: 480, y: 230 + Math.max(rowIdx, 0) * 52 });
    }
    setMenuOpen(true);
  };

  const handleActionClick = (key: keyof typeof t.toastFeedback) => {
    setMenuOpen(false);
    setToastKey(key);
    setTimeout(() => {
      setToastKey(null);
    }, 2800);
  };

  const renderFileIcon = (type: FileItem['iconType'], selected: boolean) => {
    const cls = `w-5 h-5 shrink-0 ${selected ? 'text-white' : 'text-[#0a7cff]'}`;
    switch (type) {
      case 'image':
        return <ImageIcon className={cls} strokeWidth={1.8} />;
      case 'json':
        return <FileCode className={cls} strokeWidth={1.8} />;
      case 'sh':
        return <Terminal className={cls} strokeWidth={1.8} />;
      case 'pdf':
        return <FileText className={cls} strokeWidth={1.8} />;
      case 'folder':
        return <Folder className={cls} strokeWidth={1.8} />;
    }
  };

  const dockApps = [
    { name: 'Finder', bg: 'linear-gradient(180deg,#59b8ff,#0a6ce8)', icon: <Folder className="w-6 h-6 text-white" strokeWidth={1.8} />, active: true },
    { name: 'Ghostty', bg: 'linear-gradient(180deg,#2c2e3b,#14151c)', icon: <Terminal className="w-6 h-6 text-[#4cc38a]" strokeWidth={1.9} />, active: true },
    { name: 'Cursor', bg: 'linear-gradient(180deg,#3b82f6,#1d4ed8)', icon: <Code2 className="w-6 h-6 text-white" strokeWidth={1.9} />, active: true },
    { name: 'FinderActions', bg: '#ffffff', icon: <img src="/app-icon.png" alt="" className="w-[40px] h-[40px] object-contain" />, active: true },
  ];

  return (
    <section id="demo" className="pb-20 sm:pb-28">
      <div className="hero-mac">
        <div
          aria-hidden="true"
          className="demo-glow pointer-events-none absolute inset-x-[-8%] top-[6%] -z-10 h-[75%]"
        />

        {/* Exact Shoji .tp-demo.in-mbp with measured --W px and 1440x900 16:10 virtual screen */}
        <div
          ref={wrapRef}
          className="tp-demo in-mbp"
          style={{ '--W': `${wrapWidth}px` } as React.CSSProperties}
        >
          <div className="mbp">
            <div className="mbp-lid">
              <div className="mbp-bezel">
                <div className="mbp-screen">
                  <div
                    className="demo-frame"
                    style={{ aspectRatio: `${SCREEN_W} / ${SCREEN_H}` }}
                  >
                    <div
                      ref={desktopRef}
                      onClick={() => {
                        if (menuOpen) setMenuOpen(false);
                      }}
                      className="absolute top-0 left-0 select-none overflow-hidden flex flex-col justify-between"
                      style={{
                        width: `${SCREEN_W}px`,
                        height: `${SCREEN_H}px`,
                        transform: `scale(${scale})`,
                        transformOrigin: '0 0',
                        background:
                          'radial-gradient(900px 620px at 12% 0%, rgba(120,164,255,0.85), transparent 62%), radial-gradient(760px 600px at 100% 30%, rgba(255,170,205,0.7), transparent 60%), radial-gradient(900px 600px at 45% 110%, rgba(255,206,150,0.75), transparent 60%), linear-gradient(160deg, #cfdcff, #f4d9ea 60%, #ffe6cc)',
                      }}
                    >
                      {/* 28px macOS Menu Bar — matches 3.1% notch height (27.9px) to 0.1px */}
                      <div className="h-[28px] px-4 bg-white/55 border-b border-black/6 flex items-center justify-between text-[13px] text-[#1d1d1f] font-medium z-20 shrink-0">
                        <div className="flex items-center gap-4">
                          <AppleLogo className="w-3.5 h-3.5" />
                          <span className="font-bold">Finder</span>
                          <span>File</span>
                          <span>Edit</span>
                          <span>View</span>
                          <span>Go</span>
                          <span>Window</span>
                          <span>Help</span>
                        </div>

                        <div className="flex items-center gap-3.5 text-[12.5px]">
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-black/8 font-medium text-[#1d1d1f]">
                            <Hammer className="w-3.5 h-3.5" strokeWidth={2} />
                            <span>{t.menubarReady}</span>
                          </span>
                          <Wifi className="w-3.5 h-3.5 opacity-80" />
                          <Search className="w-3.5 h-3.5 opacity-80" />
                          <span className="font-mono tabular-nums">Sat 12:41</span>
                        </div>
                      </div>

                      {/* macOS Notification Banner */}
                      {toastKey && (
                        <div
                          role="status"
                          className="absolute top-11 right-4 z-40 w-[340px] rounded-[16px] px-4 py-3 bg-white/92 backdrop-blur-xl shadow-[0_16px_38px_-8px_rgba(0,0,0,0.28),0_0_0_0.5px_rgba(0,0,0,0.12)] flex items-center gap-3 text-[#1d1d1f]"
                        >
                          <img src="/app-icon.png" alt="" className="w-8 h-8 rounded-[7px] object-contain shrink-0" />
                          <div className="min-w-0">
                            <div className="text-[12.5px] font-semibold leading-tight">
                              FinderActions
                            </div>
                            <div className="text-[13px] text-[#3f3f46] truncate mt-0.5">
                              {t.toastFeedback[toastKey]}
                            </div>
                          </div>
                        </div>
                      )}

                      {/* Centered Finder Window */}
                      <div className="flex-1 flex items-center justify-center px-12 pt-4 pb-20">
                        <div className="w-[1060px] h-[640px] rounded-[16px] overflow-hidden bg-white/96 shadow-[0_28px_70px_-16px_rgba(17,24,39,0.34),0_0_0_0.5px_rgba(0,0,0,0.18)] text-[#1d1d1f] flex flex-col">
                          {/* Finder Toolbar */}
                          <div className="h-[52px] px-5 bg-[#f3f3f5] border-b border-black/8 flex items-center justify-between shrink-0">
                            <div className="flex items-center gap-2 w-28" aria-hidden="true">
                              <span className="w-3.5 h-3.5 rounded-full bg-[#ff5f57] border border-[#e0443e]" />
                              <span className="w-3.5 h-3.5 rounded-full bg-[#febc2e] border border-[#d89e24]" />
                              <span className="w-3.5 h-3.5 rounded-full bg-[#28c840] border border-[#1aab29]" />
                            </div>

                            <div className="flex items-center gap-2.5 text-[15px] font-semibold text-[#1d1d1f]">
                              <div className="flex items-center text-[#86868b] gap-1 mr-1" aria-hidden="true">
                                <ChevronLeft className="w-4 h-4" />
                                <ChevronRight className="w-4 h-4" />
                              </div>
                              <Folder className="w-4 h-4 text-[#0a7cff]" strokeWidth={2} />
                              <span>Project-Assets</span>
                            </div>

                            <div className="w-28 text-right text-[13px] font-mono tabular-nums text-[#86868b]">
                              {t.itemCount}
                            </div>
                          </div>

                          {/* Finder Sidebar + File List */}
                          <div className="flex flex-1 min-h-0">
                            <div
                              className="w-[220px] bg-[#f2f2f5] border-r border-black/8 p-4 flex flex-col gap-6 shrink-0 text-[13.5px]"
                              aria-hidden="true"
                            >
                              <div>
                                <div className="text-[11.5px] font-semibold text-[#86868b] px-2.5 mb-1.5">
                                  {t.sidebar.favorites}
                                </div>
                                <div className="flex flex-col gap-1 text-[#3f3f46]">
                                  <div className="h-8 px-2.5 rounded-[7px] flex items-center gap-2.5">
                                    <Clock className="w-4 h-4 text-[#0a7cff]" />
                                    <span>{t.sidebar.recents}</span>
                                  </div>
                                  <div className="h-8 px-2.5 rounded-[7px] flex items-center gap-2.5">
                                    <Layers className="w-4 h-4 text-[#0a7cff]" />
                                    <span>{t.sidebar.applications}</span>
                                  </div>
                                  <div className="h-8 px-2.5 rounded-[7px] bg-black/8 font-semibold text-[#1d1d1f] flex items-center gap-2.5">
                                    <Folder className="w-4 h-4 text-[#0a7cff]" />
                                    <span>Project-Assets</span>
                                  </div>
                                  <div className="h-8 px-2.5 rounded-[7px] flex items-center gap-2.5">
                                    <FileText className="w-4 h-4 text-[#0a7cff]" />
                                    <span>{t.sidebar.documents}</span>
                                  </div>
                                </div>
                              </div>

                              <div>
                                <div className="text-[11.5px] font-semibold text-[#86868b] px-2.5 mb-1.5">
                                  {t.sidebar.tags}
                                </div>
                                <div className="flex flex-col gap-1 text-[#3f3f46]">
                                  <div className="h-8 px-2.5 flex items-center gap-2.5">
                                    <span className="w-2.5 h-2.5 rounded-full bg-[#0a7cff]" />
                                    <span>{t.sidebar.work}</span>
                                  </div>
                                  <div className="h-8 px-2.5 flex items-center gap-2.5">
                                    <span className="w-2.5 h-2.5 rounded-full bg-[#34c759]" />
                                    <span>{t.sidebar.personal}</span>
                                  </div>
                                </div>
                              </div>
                            </div>

                            <div className="flex-1 p-5 bg-white flex flex-col justify-between">
                              <div className="rounded-[11px] overflow-hidden border border-black/8 divide-y divide-black/6">
                                {FILES.map((file) => {
                                  const isSelected = selectedFile.id === file.id;
                                  return (
                                    <button
                                      key={file.id}
                                      type="button"
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        openMenuForItem(file, e.clientX || undefined, e.clientY || undefined);
                                      }}
                                      onContextMenu={(e) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                        openMenuForItem(file, e.clientX, e.clientY);
                                      }}
                                      className={`w-full h-[52px] px-4 flex items-center justify-between text-left transition-colors cursor-pointer ${
                                        isSelected
                                          ? 'bg-[#0a7cff] text-white'
                                          : 'bg-white hover:bg-black/4 text-[#1d1d1f]'
                                      }`}
                                    >
                                      <div className="flex items-center gap-3 min-w-0">
                                        {renderFileIcon(file.iconType, isSelected)}
                                        <span className="text-[15px] font-medium truncate">
                                          {file.name}
                                        </span>
                                      </div>
                                      <div className="flex items-center gap-8 text-[13.5px] shrink-0 ml-4">
                                        <span className={isSelected ? 'text-white/85' : 'text-[#86868b]'}>
                                          {file.type}
                                        </span>
                                        <span
                                          className={`${
                                            isSelected ? 'text-white/95' : 'text-[#52525b]'
                                          } font-mono tabular-nums w-20 text-right`}
                                        >
                                          {file.size}
                                        </span>
                                      </div>
                                    </button>
                                  );
                                })}
                              </div>

                              <div className="pt-3 border-t border-black/6 flex items-center justify-between text-[12.5px] text-[#86868b] font-mono">
                                <span>Macintosh HD › Users › dev › Project-Assets › {selectedFile.name}</span>
                                <span>{selectedFile.size}</span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* macOS Dock at bottom of 1440x900 desktop */}
                      <div
                        aria-hidden="true"
                        className="absolute bottom-2.5 left-1/2 -translate-x-1/2 h-[62px] px-3 rounded-[18px] bg-white/55 border border-white/60 shadow-[0_12px_30px_rgba(0,0,0,0.18)] flex items-center gap-2.5 z-20"
                      >
                        {dockApps.map((app) => (
                          <div key={app.name} className="relative flex flex-col items-center">
                            <div
                              className="w-[46px] h-[46px] rounded-[12px] shadow-[0_4px_10px_rgba(0,0,0,0.22),inset_0_1px_rgba(255,255,255,0.35)] flex items-center justify-center"
                              style={{ background: app.bg }}
                            >
                              {app.icon}
                            </div>
                            {app.active && (
                              <span className="w-1 h-1 rounded-full bg-black/65 mt-1" />
                            )}
                          </div>
                        ))}
                      </div>

                      {/* Authentic macOS Frosted Context Menu */}
                      {menuOpen && (
                        <div
                          key={selectedFile.id}
                          role="menu"
                          style={{ top: `${menuPosition.y}px`, left: `${menuPosition.x}px` }}
                          className="finder-menu-pop absolute z-30 w-[264px] rounded-[12px] p-1.5 bg-[#f6f6f8]/95 backdrop-blur-2xl shadow-[0_22px_48px_-10px_rgba(0,0,0,0.34),0_0_0_0.5px_rgba(0,0,0,0.18)] text-[14px] text-[#1d1d1f]"
                          onClick={(e) => e.stopPropagation()}
                        >
                          {selectedFile.matched.includes('open-terminal') && (
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => handleActionClick('openTerminal')}
                              className="w-full h-8 px-3 rounded-[7px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                            >
                              <Terminal className="w-4 h-4 text-[#52525b] group-hover:text-white shrink-0" />
                              <span className="truncate">{t.menuItems.openTerminal}</span>
                            </button>
                          )}

                          {selectedFile.matched.includes('open-vscode') && (
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => handleActionClick('openEditor')}
                              className="w-full h-8 px-3 rounded-[7px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                            >
                              <Code2 className="w-4 h-4 text-[#52525b] group-hover:text-white shrink-0" />
                              <span className="truncate">{t.menuItems.openEditor}</span>
                            </button>
                          )}

                          {selectedFile.matched.includes('copy-path') && (
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => handleActionClick('copyPath')}
                              className="w-full h-8 px-3 rounded-[7px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                            >
                              <Copy className="w-4 h-4 text-[#52525b] group-hover:text-white shrink-0" />
                              <span className="truncate">{t.menuItems.copyPath}</span>
                            </button>
                          )}

                          {selectedFile.matched.includes('copy-name') && (
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => handleActionClick('copyName')}
                              className="w-full h-8 px-3 rounded-[7px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                            >
                              <FileCheck2 className="w-4 h-4 text-[#52525b] group-hover:text-white shrink-0" />
                              <span className="truncate">{t.menuItems.copyName}</span>
                            </button>
                          )}

                          {selectedFile.matched.includes('convert-webp') && (
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => handleActionClick('convertWebp')}
                              className="w-full h-8 px-3 rounded-[7px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                            >
                              <ImageIcon className="w-4 h-4 text-[#52525b] group-hover:text-white shrink-0" />
                              <span className="truncate">{t.menuItems.convertWebp}</span>
                            </button>
                          )}

                          {selectedFile.matched.includes('format-json') && (
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => handleActionClick('formatJson')}
                              className="w-full h-8 px-3 rounded-[7px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                            >
                              <FileCode className="w-4 h-4 text-[#52525b] group-hover:text-white shrink-0" />
                              <span className="truncate">{t.menuItems.formatJson}</span>
                            </button>
                          )}

                          {selectedFile.matched.includes('compress') && (
                            <button
                              type="button"
                              role="menuitem"
                              onClick={() => handleActionClick('compress')}
                              className="w-full h-8 px-3 rounded-[7px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                            >
                              <Archive className="w-4 h-4 text-[#52525b] group-hover:text-white shrink-0" />
                              <span className="truncate">{t.menuItems.compress}</span>
                            </button>
                          )}

                          <div className="h-px bg-black/10 my-1.5" />

                          <div className="h-7 px-3 flex items-center justify-between text-[13px] text-[#86868b]">
                            <span>Get Info</span>
                            <span className="font-mono text-[11.5px]">⌘I</span>
                          </div>
                          <div className="h-7 px-3 flex items-center justify-between text-[13px] text-[#86868b]">
                            <span>Quick Look</span>
                            <span className="font-mono text-[11.5px]">Space</span>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>

                  <span className="mbp-notch" aria-hidden="true">
                    <i />
                  </span>
                  <span className="mbp-glare" aria-hidden="true" />
                </div>
              </div>
            </div>

            <div className="mbp-hinge" aria-hidden="true" />
            <div className="mbp-base" aria-hidden="true" />
            <div className="mbp-feet" aria-hidden="true">
              <i />
              <i />
            </div>
            <div className="mbp-shadow" aria-hidden="true" />
          </div>
        </div>

        <p className="mt-5 text-center text-[13px] text-[var(--color-ink-3)]">
          {t.caption}
        </p>
      </div>
    </section>
  );
};
