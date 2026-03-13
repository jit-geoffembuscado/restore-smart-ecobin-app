import { Component } from '@angular/core';
import { NavigationEnd, Router, RouterLink, RouterLinkActive } from '@angular/router';
import {
  IonApp,
  IonSplitPane,
  IonMenu,
  IonContent,
  IonList,
  IonListHeader,
  IonNote,
  IonMenuToggle,
  IonItem,
  IonIcon,
  IonLabel,
  IonRouterOutlet,
} from '@ionic/angular/standalone';
import { filter } from 'rxjs';
import { addIcons } from 'ionicons';
import { buildOutline, buildSharp, homeOutline, homeSharp } from 'ionicons/icons';

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
  standalone: true,
  imports: [
    RouterLink,
    RouterLinkActive,
    IonApp,
    IonSplitPane,
    IonMenu,
    IonContent,
    IonList,
    IonListHeader,
    IonNote,
    IonMenuToggle,
    IonItem,
    IonIcon,
    IonLabel,
    IonRouterOutlet,
  ],
})
export class AppComponent {
  showMenu = false;
  public appPages = [
    { title: 'Home Dashboard', url: '/home', icon: 'home' },
    { title: 'Machines', url: '/machines-index', icon: 'build' },
  ];

  constructor(private router: Router) {
    addIcons({ homeOutline, homeSharp, buildOutline, buildSharp });
    this.setMenuVisibility(this.router.url);

    this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe((event) => this.setMenuVisibility(event.urlAfterRedirects));
  }

  private setMenuVisibility(url: string): void {
    this.showMenu = url.startsWith('/home') || url.startsWith('/machines');
  }
}
