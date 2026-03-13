import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import {
  IonButton,
  IonContent,
  IonHeader,
  IonInput,
  IonItem,
  IonLabel,
  IonTitle,
  IonToolbar,
} from '@ionic/angular/standalone';
import { SupabaseService } from '../../services/supabase.service';

@Component({
  selector: 'app-register',
  templateUrl: './register.page.html',
  styleUrls: ['./register.page.scss'],
  standalone: true,
  imports: [
    FormsModule,
    RouterLink,
    IonHeader,
    IonToolbar,
    IonTitle,
    IonContent,
    IonItem,
    IonLabel,
    IonInput,
    IonButton,
  ],
})
export class RegisterPage {
  email = '';
  password = '';

  constructor(private supabase: SupabaseService, private router: Router) {}

  async handleRegister() {
    const { error } = await this.supabase.signUp(this.email, this.password);

    if (error) {
      alert(error.message);
      return;
    }

    alert('Registration successful! Check your email for confirmation.');
    this.router.navigateByUrl('/login', { replaceUrl: true });
  }
}
