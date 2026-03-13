import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { 
  ReactiveFormsModule, 
  FormBuilder, 
  FormGroup, 
  Validators 
} from '@angular/forms';
import { 
  IonicModule, 
  LoadingController, 
  ToastController 
} from '@ionic/angular'; // Import IonicModule or specific components
import { Router, RouterModule } from '@angular/router'; 
import { SupabaseService } from '../../services/supabase.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.page.html',
  styleUrls: ['./login.page.scss'],
  standalone: true,
  imports: [
    CommonModule, 
    IonicModule,       // This allows ion-content, ion-item, etc.
    ReactiveFormsModule, 
    RouterModule       // This allows routerLink to work
  ]
})
export class LoginPage implements OnInit {
  loginForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private supabase: SupabaseService,
    private router: Router,
    private loadingCtrl: LoadingController,
    private toastCtrl: ToastController
  ) {
    // Correctly initializing the form
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  ngOnInit() {}

  async onLogin() {
    if (this.loginForm.invalid) return;

    const loading = await this.loadingCtrl.create({ 
      message: 'Authenticating...',
      spinner: 'circles'
    });
    await loading.present();

    const { email, password } = this.loginForm.value;
    
    // Using your Supabase service
    const { data, error } = await this.supabase.signIn(email, password);

    await loading.dismiss();

    if (error) {
      this.showToast(error.message, 'danger');
    } else {
      // replaceUrl: true prevents users from hitting 'back' to the login screen
      this.router.navigateByUrl('/home', { replaceUrl: true });
    }
  }

  async showToast(message: string, color: 'success' | 'danger') {
    const toast = await this.toastCtrl.create({
      message,
      duration: 3000,
      color,
      position: 'bottom',
      buttons: [{ text: 'OK', role: 'cancel' }]
    });
    await toast.present();
  }
}