import type { Dog, Report } from '../types'
export const dogs: Dog[] = [
  { id: '1', name: 'Duman', gender: 'Erkek', healthStatus: 'Normal', updatedAt: 'Bugün, 10:24', active: true },
  { id: '2', name: 'Tarçın', gender: 'Dişi', healthStatus: 'Gözlem Altında', updatedAt: 'Bugün, 09:10', active: true },
  { id: '3', name: 'Boncuk', gender: 'Erkek', healthStatus: 'İyileşiyor', updatedAt: 'Dün, 16:42', active: true },
]
export const reports: Report[] = [
  { id: 'R-104', dogName: 'Tarçın', category: 'Davranış', severity: 'Orta', createdAt: 'Bugün, 09:18', status: 'Yeni' },
  { id: 'R-103', dogName: 'Duman', category: 'Sağlık', severity: 'Düşük', createdAt: 'Dün, 15:30', status: 'İnceleniyor' },
]
