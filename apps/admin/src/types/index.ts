export type HealthStatus = 'Normal' | 'Gözlem Altında' | 'Tedavi Altında' | 'İyileşiyor'
export interface Dog { id: string; name: string; gender: string; healthStatus: HealthStatus; updatedAt: string; active: boolean }
export interface Report { id: string; dogName: string; category: string; severity: 'Düşük' | 'Orta' | 'Yüksek'; createdAt: string; status: string }
