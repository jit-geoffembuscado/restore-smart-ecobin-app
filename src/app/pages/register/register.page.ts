import { SupabaseService } from './../../services/supabase.service';
import { Router } from '@angular/router';
// ... standard imports

export class RegisterPage {
  email = '';
  password = '';

  constructor(private supabase: SupabaseService, private router: Router) {}

  async handleRegister() {
    const { data, error } = await this.supabase.signUp(this.email, this.password);
    if (error) {
      alert(error.message);
    } else {
      alert('Registration successful! Check your email for confirmation.');
      this.router.navigateByUrl('/login');
    }
  }
}