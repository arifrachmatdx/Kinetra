class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const biodata = '/biodata';
  static const home = '/home';
  static const workouts = '/workouts';
  static const detection = '/detection';
  static const result = '/result';
  static const history = '/history';
  static const profile = '/profile';

  static String detectionPath(String latihanId) => '/detection/$latihanId';
  static String historyDetailPath(String id) => '/history/$id';
}
