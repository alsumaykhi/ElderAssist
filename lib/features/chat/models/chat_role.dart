enum ChatRole {
  user,
  assistant;

  static ChatRole fromFirestore(String? raw) {
    switch (raw) {
      case 'assistant':
        return ChatRole.assistant;
      default:
        return ChatRole.user;
    }
  }
}
