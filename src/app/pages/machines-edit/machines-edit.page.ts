import { Component, OnInit } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
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
  selector: 'app-machines-edit',
  templateUrl: './machines-edit.page.html',
  styleUrls: ['./machines-edit.page.scss'],
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
export class MachinesEditPage implements OnInit {
  machineCode = '';
  loading = false;
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
    private route: ActivatedRoute,
    private router: Router,
    private supabaseService: SupabaseService,
    private toastController: ToastController,
  ) {}

  ngOnInit(): void {
    const code = this.route.snapshot.paramMap.get('code');

    if (!code) {
      this.router.navigate(['/machines-index']);
      return;
    }

    this.machineCode = code;
    this.loadMachine();
  }

  async loadMachine(): Promise<void> {
    this.loading = true;

    const { data, error } = await this.supabaseService.client
      .from('machines')
      .select('*')
      .eq('code', this.machineCode)
      .single<Machine>();

    this.loading = false;

    if (error || !data) {
      await this.showToast(error?.message ?? 'Machine not found.', 'danger');
      await this.router.navigate(['/machines-index']);
      return;
    }

    this.form.patchValue(data);
  }

  async updateMachine(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.saving = true;

    const { error } = await this.supabaseService.client
      .from('machines')
      .update(this.form.getRawValue())
      .eq('code', this.machineCode);

    this.saving = false;

    if (error) {
      await this.showToast(error.message, 'danger');
      return;
    }

    await this.showToast('Machine updated successfully.', 'success');
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
