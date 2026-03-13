import { Component, OnInit } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import {
  AlertController,
  IonButton,
  IonButtons,
  IonContent,
  IonHeader,
  IonItem,
  IonLabel,
  IonList,
  IonMenuButton,
  IonSpinner,
  IonTitle,
  IonToolbar,
  ToastController,
} from '@ionic/angular/standalone';
import { SupabaseService } from '../../services/supabase.service';

interface Machine {
  code: string;
  title: string;
  qr_backdoor: string;
  maintenance_incentive_limit: number;
  maintenance_start_time: string;
  maintenance_end_time: string;
  active: boolean;
}

@Component({
  selector: 'app-machines-index',
  templateUrl: './machines-index.page.html',
  styleUrls: ['./machines-index.page.scss'],
  standalone: true,
  imports: [
    RouterLink,
    IonHeader,
    IonToolbar,
    IonButtons,
    IonMenuButton,
    IonTitle,
    IonContent,
    IonButton,
    IonList,
    IonItem,
    IonLabel,
    IonSpinner,
  ],
})
export class MachinesIndexPage implements OnInit {
  machines: Machine[] = [];
  loading = false;

  constructor(
    private supabaseService: SupabaseService,
    private alertController: AlertController,
    private toastController: ToastController,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.loadMachines();
  }

  async loadMachines(): Promise<void> {
    this.loading = true;
    const { data, error } = await this.supabaseService.client
      .from('machines')
      .select('*')
      .order('code', { ascending: true });

    if (error) {
      await this.showToast(error.message, 'danger');
      this.loading = false;
      return;
    }

    this.machines = (data ?? []) as Machine[];
    this.loading = false;
  }

  goToEdit(code: string): void {
    this.router.navigate(['/machines-edit', code]);
  }

  async deleteMachine(code: string): Promise<void> {
    const alert = await this.alertController.create({
      header: 'Delete machine',
      message: `Are you sure you want to delete machine ${code}?`,
      buttons: [
        { text: 'Cancel', role: 'cancel' },
        {
          text: 'Delete',
          role: 'destructive',
          handler: async () => {
            const { error } = await this.supabaseService.client
              .from('machines')
              .delete()
              .eq('code', code);

            if (error) {
              await this.showToast(error.message, 'danger');
              return;
            }

            await this.showToast('Machine deleted successfully.', 'success');
            await this.loadMachines();
          },
        },
      ],
    });

    await alert.present();
  }

  private async showToast(
    message: string,
    color: 'success' | 'danger',
  ): Promise<void> {
    const toast = await this.toastController.create({
      message,
      color,
      duration: 2000,
      position: 'top',
    });

    await toast.present();
  }
}
