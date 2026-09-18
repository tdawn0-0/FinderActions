export type Language = 'en' | 'zh';

export interface ActionItem {
  id: string;
  name: string;
  category: 'terminal' | 'editor' | 'shell' | 'system';
  icon: string;
  commandSnippet: string;
  description: {
    en: string;
    zh: string;
  };
  filterRule?: string;
}

export interface FinderFile {
  id: string;
  name: string;
  type: 'file' | 'folder' | 'code' | 'image' | 'archive';
  extension?: string;
  size: string;
  dateModified: string;
  matchedActions: string[];
}

export interface CorePillar {
  icon: string;
  title: string;
  desc: string;
}
