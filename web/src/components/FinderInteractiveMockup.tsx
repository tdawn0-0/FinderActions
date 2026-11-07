import React, { useState, useRef } from 'react';
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
  Check,
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

export const FinderInteractiveMockup: React.FC<FinderInteractiveMockupProps> = ({ lang }) => {
  const t = translations[lang].demo;

  const [selectedFile, setSelectedFile] = useState<FileItem>(FILES[0]);
  const [menuOpen, setMenuOpen] = useState(true);
  const [menuPosition, setMenuPosition] = useState({ x: 256, y: 122 });
  const [toastKey, setToastKey] = useState<keyof typeof t.toastFeedback | null>(null);
  const screenRef = useRef<HTMLDivElement>(null);

  const openMenuForItem = (file: FileItem, clientX?: number, clientY?: number) => {
    setSelectedFile(file);
    if (screenRef.current && clientX !== undefined && clientY !== undefined) {
      const rect = screenRef.current.getBoundingClientRect();
      const clickX = Math.min(Math.max(clientX - rect.left, 32), Math.max(rect.width - 268, 32));
      const clickY = Math.min(Math.max(clientY - rect.top, 68), Math.max(rect.height - 260, 68));
      setMenuPosition({ x: clickX, y: clickY });
    } else {
      const rowIdx = FILES.findIndex((item) => item.id === file.id);
      setMenuPosition({ x: 256, y: 122 + Math.max(rowIdx, 0) * 38 });
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
    const cls = `w-4 h-4 shrink-0 ${selected ? 'text-white' : 'text-[#0a7cff]'}`;
    switch (type) {
      case 'image':
        return <ImageIcon className={cls} strokeWidth={1.7} />;
      case 'json':
        return <FileCode className={cls} strokeWidth={1.7} />;
      case 'sh':
        return <Terminal className={cls} strokeWidth={1.7} />;
      case 'pdf':
        return <FileText className={cls} strokeWidth={1.7} />;
      case 'folder':
        return <Folder className={cls} strokeWidth={1.7} />;
    }
  };

  return (
    <section id="demo" className="pb-20 sm:pb-28">
      <div className="container-page">
        <div className="max-w-[1040px] mx-auto">
          {/* Shoji Sculpted MacBook Pro Hardware Frame */}
          <div className="mbp">
            <div className="mbp-lid">
              <div className="mbp-bezel">
                <div className="mbp-notch" aria-hidden="true">
                  <i />
                </div>

                {/* macOS Sequoia Desktop Screen */}
                <div
                  ref={screenRef}
                  onClick={() => {
                    if (menuOpen) setMenuOpen(false);
                  }}
                  className="relative rounded-[11px] overflow-hidden select-none min-h-[440px] sm:min-h-[490px] flex flex-col"
                  style={{
                    background:
                      'radial-gradient(85% 90% at 18% 15%, #dbeafe 0%, transparent 60%), radial-gradient(75% 80% at 85% 20%, #fde68a 0%, transparent 55%), linear-gradient(160deg, #bfdbfe 0%, #e0e7ff 52%, #fae8ff 100%)',
                  }}
                >
                  {/* macOS Top Menu Bar */}
                  <div className="h-7 px-3.5 bg-white/55 backdrop-blur-md border-b border-black/6 flex items-center justify-between text-[12px] text-[#1d1d1f] font-medium z-20">
                    <div className="flex items-center gap-3.5">
                      <AppleLogo className="w-3.5 h-3.5" />
                      <span className="font-semibold">Finder</span>
                      <span className="hidden sm:inline text-[#1d1d1f]/75">File</span>
                      <span className="hidden sm:inline text-[#1d1d1f]/75">Edit</span>
                      <span className="hidden sm:inline text-[#1d1d1f]/75">View</span>
                      <span className="hidden sm:inline text-[#1d1d1f]/75">Go</span>
                    </div>

                    <div className="flex items-center gap-3 text-[11.5px]">
                      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-black/7 text-[#1d1d1f]">
                        <Hammer className="w-3 h-3" strokeWidth={2} />
                        <span className="hidden sm:inline">{t.menubarReady}</span>
                      </span>
                      <span className="font-mono tabular-nums text-[#1d1d1f]/80">12:41</span>
                    </div>
                  </div>

                  {/* macOS Banner Notification inside screen */}
                  {toastKey && (
                    <div
                      role="status"
                      className="absolute top-10 right-3.5 z-40 max-w-xs rounded-[14px] px-3.5 py-2.5 bg-white/92 backdrop-blur-xl shadow-[0_12px_32px_-8px_rgba(0,0,0,0.28),0_0_0_0.5px_rgba(0,0,0,0.1)] flex items-center gap-2.5 text-[#1d1d1f]"
                    >
                      <span className="w-5 h-5 rounded-full bg-[#0a7cff] text-white flex items-center justify-center shrink-0">
                        <Check className="w-3 h-3" strokeWidth={2.5} />
                      </span>
                      <div className="min-w-0">
                        <div className="text-[11px] font-semibold leading-tight">FinderActions</div>
                        <div className="text-[11.5px] text-[#3f3f46] truncate">
                          {t.toastFeedback[toastKey]}
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Finder Window on the Desktop */}
                  <div className="flex-1 p-3 sm:p-6 flex items-center justify-center">
                    <div className="w-full max-w-[880px] rounded-[14px] overflow-hidden bg-white/95 backdrop-blur-xl shadow-[0_24px_60px_-15px_rgba(15,23,42,0.35),0_0_0_1px_rgba(15,23,42,0.1)] text-[#1d1d1f]">
                      {/* Finder Window Toolbar */}
                      <div className="h-11 px-4 bg-[#f5f5f7] border-b border-black/8 flex items-center justify-between">
                        <div className="flex items-center gap-2 w-20" aria-hidden="true">
                          <span className="w-3 h-3 rounded-full bg-[#ff5f57] border border-[#e0443e]" />
                          <span className="w-3 h-3 rounded-full bg-[#febc2e] border border-[#d89e24]" />
                          <span className="w-3 h-3 rounded-full bg-[#28c840] border border-[#1aab29]" />
                        </div>

                        <div className="flex items-center gap-2 text-[13px] font-semibold text-[#1d1d1f]">
                          <div className="hidden sm:flex items-center text-[#86868b] gap-1 mr-1" aria-hidden="true">
                            <ChevronLeft className="w-4 h-4" />
                            <ChevronRight className="w-4 h-4" />
                          </div>
                          <Folder className="w-4 h-4 text-[#0a7cff]" strokeWidth={1.8} />
                          <span>Project-Assets</span>
                        </div>

                        <div className="w-20 text-right text-[12px] font-mono tabular-nums text-[#86868b]">
                          {t.itemCount}
                        </div>
                      </div>

                      {/* Finder Sidebar + File Table */}
                      <div className="flex min-h-[320px]">
                        <div
                          className="w-[196px] bg-[#f2f2f5]/90 border-r border-black/7 p-3 hidden sm:flex flex-col gap-5 shrink-0 text-[12.5px]"
                          aria-hidden="true"
                        >
                          <div>
                            <div className="text-[11px] font-semibold text-[#86868b] px-2 mb-1">
                              {t.sidebar.favorites}
                            </div>
                            <div className="flex flex-col gap-0.5 text-[#3f3f46]">
                              <div className="h-7 px-2 rounded-[7px] flex items-center gap-2">
                                <Clock className="w-3.5 h-3.5 text-[#0a7cff]" />
                                <span>{t.sidebar.recents}</span>
                              </div>
                              <div className="h-7 px-2 rounded-[7px] flex items-center gap-2">
                                <Layers className="w-3.5 h-3.5 text-[#0a7cff]" />
                                <span>{t.sidebar.applications}</span>
                              </div>
                              <div className="h-7 px-2 rounded-[7px] bg-black/8 font-medium text-[#1d1d1f] flex items-center gap-2">
                                <Folder className="w-3.5 h-3.5 text-[#0a7cff]" />
                                <span>Project-Assets</span>
                              </div>
                              <div className="h-7 px-2 rounded-[7px] flex items-center gap-2">
                                <FileText className="w-3.5 h-3.5 text-[#0a7cff]" />
                                <span>{t.sidebar.documents}</span>
                              </div>
                            </div>
                          </div>

                          <div>
                            <div className="text-[11px] font-semibold text-[#86868b] px-2 mb-1">
                              {t.sidebar.tags}
                            </div>
                            <div className="flex flex-col gap-0.5 text-[#3f3f46]">
                              <div className="h-7 px-2 flex items-center gap-2">
                                <span className="w-2.5 h-2.5 rounded-full bg-[#0a7cff]" />
                                <span>{t.sidebar.work}</span>
                              </div>
                              <div className="h-7 px-2 flex items-center gap-2">
                                <span className="w-2.5 h-2.5 rounded-full bg-[#34c759]" />
                                <span>{t.sidebar.personal}</span>
                              </div>
                            </div>
                          </div>
                        </div>

                        <div className="flex-1 p-3 sm:p-4 bg-white flex flex-col justify-between overflow-x-auto">
                          <div className="rounded-[9px] overflow-hidden border border-black/7 divide-y divide-black/6">
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
                                  className={`w-full h-[38px] px-3 flex items-center justify-between text-left transition-colors cursor-pointer ${
                                    isSelected
                                      ? 'bg-[#0a7cff] text-white'
                                      : 'bg-white hover:bg-black/4 text-[#1d1d1f]'
                                  }`}
                                >
                                  <div className="flex items-center gap-2.5 min-w-0">
                                    {renderFileIcon(file.iconType, isSelected)}
                                    <span className="text-[13px] font-medium truncate">
                                      {file.name}
                                    </span>
                                  </div>
                                  <div className="flex items-center gap-6 text-[12px] shrink-0 ml-4">
                                    <span className={isSelected ? 'text-white/85' : 'text-[#86868b]'}>
                                      {file.type}
                                    </span>
                                    <span
                                      className={`${
                                        isSelected ? 'text-white/95' : 'text-[#52525b]'
                                      } font-mono tabular-nums w-16 text-right`}
                                    >
                                      {file.size}
                                    </span>
                                  </div>
                                </button>
                              );
                            })}
                          </div>

                          <div className="mt-3 pt-2.5 border-t border-black/6 flex items-center justify-between text-[11.5px] text-[#86868b] font-mono">
                            <span>Macintosh HD › Users › dev › Project-Assets › {selectedFile.name}</span>
                            <span>{selectedFile.size}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Authentic macOS Light Frosted Context Menu */}
                  {menuOpen && (
                    <div
                      key={selectedFile.id}
                      role="menu"
                      style={{ top: `${menuPosition.y}px`, left: `${menuPosition.x}px` }}
                      className="finder-menu-pop absolute z-30 w-60 rounded-[11px] p-1.5 bg-[#f6f6f8]/94 backdrop-blur-2xl shadow-[0_18px_40px_-10px_rgba(0,0,0,0.32),0_0_0_0.5px_rgba(0,0,0,0.16)] text-[13px] text-[#1d1d1f]"
                      onClick={(e) => e.stopPropagation()}
                    >
                      {selectedFile.matched.includes('open-terminal') && (
                        <button
                          type="button"
                          role="menuitem"
                          onClick={() => handleActionClick('openTerminal')}
                          className="w-full h-7 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                        >
                          <Terminal className="w-3.5 h-3.5 text-[#52525b] group-hover:text-white shrink-0" />
                          <span className="truncate">{t.menuItems.openTerminal}</span>
                        </button>
                      )}

                      {selectedFile.matched.includes('open-vscode') && (
                        <button
                          type="button"
                          role="menuitem"
                          onClick={() => handleActionClick('openEditor')}
                          className="w-full h-7 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                        >
                          <Code2 className="w-3.5 h-3.5 text-[#52525b] group-hover:text-white shrink-0" />
                          <span className="truncate">{t.menuItems.openEditor}</span>
                        </button>
                      )}

                      {selectedFile.matched.includes('copy-path') && (
                        <button
                          type="button"
                          role="menuitem"
                          onClick={() => handleActionClick('copyPath')}
                          className="w-full h-7 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                        >
                          <Copy className="w-3.5 h-3.5 text-[#52525b] group-hover:text-white shrink-0" />
                          <span className="truncate">{t.menuItems.copyPath}</span>
                        </button>
                      )}

                      {selectedFile.matched.includes('copy-name') && (
                        <button
                          type="button"
                          role="menuitem"
                          onClick={() => handleActionClick('copyName')}
                          className="w-full h-7 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                        >
                          <FileCheck2 className="w-3.5 h-3.5 text-[#52525b] group-hover:text-white shrink-0" />
                          <span className="truncate">{t.menuItems.copyName}</span>
                        </button>
                      )}

                      {selectedFile.matched.includes('convert-webp') && (
                        <button
                          type="button"
                          role="menuitem"
                          onClick={() => handleActionClick('convertWebp')}
                          className="w-full h-7 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                        >
                          <ImageIcon className="w-3.5 h-3.5 text-[#52525b] group-hover:text-white shrink-0" />
                          <span className="truncate">{t.menuItems.convertWebp}</span>
                        </button>
                      )}

                      {selectedFile.matched.includes('format-json') && (
                        <button
                          type="button"
                          role="menuitem"
                          onClick={() => handleActionClick('formatJson')}
                          className="w-full h-7 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                        >
                          <FileCode className="w-3.5 h-3.5 text-[#52525b] group-hover:text-white shrink-0" />
                          <span className="truncate">{t.menuItems.formatJson}</span>
                        </button>
                      )}

                      {selectedFile.matched.includes('compress') && (
                        <button
                          type="button"
                          role="menuitem"
                          onClick={() => handleActionClick('compress')}
                          className="w-full h-7 px-2.5 rounded-[6px] flex items-center gap-2.5 hover:bg-[#0a7cff] hover:text-white text-left cursor-pointer group"
                        >
                          <Archive className="w-3.5 h-3.5 text-[#52525b] group-hover:text-white shrink-0" />
                          <span className="truncate">{t.menuItems.compress}</span>
                        </button>
                      )}

                      <div className="h-px bg-black/10 my-1" />

                      <div className="h-6 px-2.5 flex items-center justify-between text-[12px] text-[#86868b]">
                        <span>Get Info</span>
                        <span className="font-mono text-[11px]">⌘I</span>
                      </div>
                      <div className="h-6 px-2.5 flex items-center justify-between text-[12px] text-[#86868b]">
                        <span>Quick Look</span>
                        <span className="font-mono text-[11px]">Space</span>
                      </div>
                    </div>
                  )}
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

          <p className="mt-4 text-center text-[13px] text-[var(--color-ink-3)]">
            {t.caption}
          </p>
        </div>
      </div>
    </section>
  );
};
