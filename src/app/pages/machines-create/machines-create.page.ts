import { Component } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import {
  IonButton,
  IonButtons,
  IonCheckbox,
  IonContent,
  IonHeader,
  IonInput,
  IonItem,
  IonLabel,
  IonMenuButton,
  IonTitle,
  IonToolbar,
  ToastController,
} from '@ionic/angular/standalone';
import { SupabaseService } from '../../services/supabase.service';

@Component({
  selector: 'app-machines-create',
  templateUrl: './machines-create.page.html',
  styleUrls: ['./machines-create.page.scss'],
  standalone: true,
  imports: [
    ReactiveFormsModule,
    IonHeader,
    IonToolbar,
    IonButtons,
    IonMenuButton,
    IonTitle,
    IonContent,
    IonItem,
    IonLabel,
    IonInput,
    IonCheckbox,
    IonButton,
  ],
})
export class MachinesCreatePage {
  saving = false;

  form = this.formBuilder.group({
    code: ['', [Validators.required]],
    title: ['', [Validators.required]],
    qr_backdoor: ['', [Validators.required, Validators.minLength(7), Validators.maxLength(7)]],
    maintenance_incentive_limit: [2, [Validators.required, Validators.min(0), Validators.max(127)]],
    maintenance_start_time: ['00:00:00', [Validators.required]],
    maintenance_end_time: ['23:59:00', [Validators.required]],
    active: [true, [Validators.required]],
  });

  constructor(
    private formBuilder: FormBuilder,
    private supabaseService: SupabaseService,
    private toastController: ToastController,
    private router: Router,
  ) {}

  async saveMachine(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.saving = true;
    const payload = this.form.getRawValue();

    const { error } = await this.supabaseService.client.from('machines').insert(payload);

    this.saving = false;

    if (error) {
      await this.showToast(error.message, 'danger');
      return;
    }

    await this.showToast('Machine created successfully.', 'success');
    await this.router.navigate(['/machines-index']);
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
