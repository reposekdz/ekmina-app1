import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  
  static const List<Locale> supportedLocales = [
    Locale('rw'),
    Locale('en'),
    Locale('fr'),
  ];
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'rw': {
      'app_name': 'E-Kimina Rwanda',
      'welcome': 'Murakaza neza',
      'login': 'Injira',
      'register': 'Iyandikishe',
      'phone_number': 'Nimero ya telefone',
      'password': 'Ijambo ryibanga',
      'name': 'Izina',
      'nid': 'Indangamuntu',
      'create_group': 'Kora Ikimina',
      'join_group': 'Injira mu kimina',
      'my_groups': 'Ibimina byanjye',
      'deposit': 'Tanga',
      'loan': 'Inguzanyo',
      'balance': 'Amafaranga',
      'shares': 'Imigabane',
      'penalties': 'Amande',
      'notifications': 'Ubutumwa',
      'profile': 'Umwirondoro',
      'settings': 'Igenamiterere',
      'logout': 'Sohoka',
      'confirm': 'Emeza',
      'cancel': 'Hagarika',
      'save': 'Bika',
      'delete': 'Siba',
      'edit': 'Hindura',
      'search': 'Shakisha',
      'filter': 'Shungura',
      'loading': 'Tegereza...',
      'error': 'Ikosa',
      'success': 'Byagenze neza',
      'warning': 'Burira',
      'info': 'Amakuru',
      'group_name': 'Izina ryikimina',
      'share_value': 'Agaciro kumugabane',
      'join_fee': 'Amafaranga yo kwinjira',
      'penalty_amount': 'Amande',
      'interest_rate': 'Inyungu',
      'request_loan': 'Saba inguzanyo',
      'approve': 'Emeza',
      'reject': 'Anga',
      'pending': 'Bitegereje',
      'active': 'Birakora',
      'completed': 'Byarangiye',
      'failed': 'Byanze',
    },
    'en': {
      'app_name': 'E-Kimina Rwanda',
      'welcome': 'Welcome',
      'login': 'Login',
      'register': 'Register',
      'phone_number': 'Phone Number',
      'password': 'Password',
      'name': 'Name',
      'nid': 'National ID',
      'create_group': 'Create Group',
      'join_group': 'Join Group',
      'my_groups': 'My Groups',
      'deposit': 'Deposit',
      'loan': 'Loan',
      'balance': 'Balance',
      'shares': 'Shares',
      'penalties': 'Penalties',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'filter': 'Filter',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Information',
      'group_name': 'Group Name',
      'share_value': 'Share Value',
      'join_fee': 'Joining Fee',
      'penalty_amount': 'Penalty Amount',
      'interest_rate': 'Interest Rate',
      'request_loan': 'Request Loan',
      'approve': 'Approve',
      'reject': 'Reject',
      'pending': 'Pending',
      'active': 'Active',
      'completed': 'Completed',
      'failed': 'Failed',
    },
    'fr': {
      'app_name': 'E-Kimina Rwanda',
      'welcome': 'Bienvenue',
      'login': 'Connexion',
      'register': 'S\'inscrire',
      'phone_number': 'Numéro de téléphone',
      'password': 'Mot de passe',
      'name': 'Nom',
      'nid': 'Carte d\'identité',
      'create_group': 'Créer un groupe',
      'join_group': 'Rejoindre un groupe',
      'my_groups': 'Mes groupes',
      'deposit': 'Dépôt',
      'loan': 'Prêt',
      'balance': 'Solde',
      'shares': 'Parts',
      'penalties': 'Pénalités',
      'notifications': 'Notifications',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'logout': 'Déconnexion',
      'confirm': 'Confirmer',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'search': 'Rechercher',
      'filter': 'Filtrer',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'warning': 'Avertissement',
      'info': 'Information',
      'group_name': 'Nom du groupe',
      'share_value': 'Valeur de la part',
      'join_fee': 'Frais d\'adhésion',
      'penalty_amount': 'Montant de la pénalité',
      'interest_rate': 'Taux d\'intérêt',
      'request_loan': 'Demander un prêt',
      'approve': 'Approuver',
      'reject': 'Rejeter',
      'pending': 'En attente',
      'active': 'Actif',
      'completed': 'Terminé',
      'failed': 'Échoué',
    },
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['rw', 'en', 'fr'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
