class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  // Auth translations
  String get welcomeBack => _translate('Welcome Back', 'Murakaza Neza', 'Bienvenue');
  String get login => _translate('Login', 'Injira', 'Connexion');
  String get register => _translate('Register', 'Iyandikishe', 'S\'inscrire');
  String get phoneNumber => _translate('Phone Number', 'Nimero ya Telefoni', 'Numéro de téléphone');
  String get password => _translate('Password', 'Ijambo ryibanga', 'Mot de passe');
  String get confirmPassword => _translate('Confirm Password', 'Emeza ijambo ryibanga', 'Confirmer le mot de passe');
  String get forgotPassword => _translate('Forgot Password?', 'Wibagiwe ijambo ryibanga?', 'Mot de passe oublié?');
  String get dontHaveAccount => _translate('Don\'t have an account?', 'Ntufite konti?', 'Vous n\'avez pas de compte?');
  String get alreadyHaveAccount => _translate('Already have an account?', 'Ufite konti?', 'Vous avez déjà un compte?');
  String get fullName => _translate('Full Name', 'Amazina yawe yose', 'Nom complet');
  String get province => _translate('Province', 'Intara', 'Province');
  String get district => _translate('District', 'Akarere', 'District');
  String get sector => _translate('Sector', 'Umurenge', 'Secteur');
  String get cell => _translate('Cell', 'Akagari', 'Cellule');
  String get village => _translate('Village', 'Umudugudu', 'Village');
  String get selectProvince => _translate('Select Province', 'Hitamo Intara', 'Sélectionner la province');
  String get selectDistrict => _translate('Select District', 'Hitamo Akarere', 'Sélectionner le district');
  String get selectSector => _translate('Select Sector', 'Hitamo Umurenge', 'Sélectionner le secteur');
  String get selectCell => _translate('Select Cell', 'Hitamo Akagari', 'Sélectionner la cellule');
  String get selectVillage => _translate('Select Village', 'Hitamo Umudugudu', 'Sélectionner le village');

  String _translate(String en, String rw, String fr) {
    switch (languageCode) {
      case 'rw':
        return rw;
      case 'fr':
        return fr;
      default:
        return en;
    }
  }
}
