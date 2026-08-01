enum SyncStatus {
  synced,
  syncing,
  offline,
  pendingChanges,
}

extension SyncStatusExtension on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.pendingChanges:
        return 'Pending Changes';
    }
  }
}
