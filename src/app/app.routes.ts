import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full',
  },
  {
    path: 'login',
    loadComponent: () =>
      import('./pages/login/login.page').then((m) => m.LoginPage),
  },
  {
    path: 'register',
    loadComponent: () =>
      import('./pages/register/register.page').then((m) => m.RegisterPage),
  },
  {
    path: 'home',
    loadComponent: () => import('./pages/home/home.page').then((m) => m.HomePage),
  },
  {
    path: 'machines-index',
    loadComponent: () =>
      import('./pages/machines-index/machines-index.page').then(
        (m) => m.MachinesIndexPage,
      ),
  },
  {
    path: 'machines-create',
    loadComponent: () =>
      import('./pages/machines-create/machines-create.page').then(
        (m) => m.MachinesCreatePage,
      ),
  },
  {
    path: 'machines-edit/:code',
    loadComponent: () =>
      import('./pages/machines-edit/machines-edit.page').then(
        (m) => m.MachinesEditPage,
      ),
  },
];
