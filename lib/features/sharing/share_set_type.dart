enum ShareSetType { warmup, work, failure, dropset, superset, other }

ShareSetType shareSetTypeFromRaw(String? raw) {
  final normalized = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
  switch (normalized) {
    case '':
    case 'normal':
    case 'work':
    case 'working':
      return ShareSetType.work;
    case 'warmup':
    case 'warm_up':
      return ShareSetType.warmup;
    case 'failure':
      return ShareSetType.failure;
    case 'dropset':
    case 'drop_set':
      return ShareSetType.dropset;
    case 'superset':
    case 'super_set':
      return ShareSetType.superset;
    default:
      return ShareSetType.other;
  }
}
