/// Official 8 Staff Roles from `F:\FTH\app\Models\User.php`.
enum StaffRole {
  owner(
    key: 'owner',
    label: 'Owner / Executive',
    department: 'Executive Management',
    defaultPermissions: ['*'],
  ),
  operationsManager(
    key: 'operations_manager',
    label: 'Operations Manager',
    department: 'Operations & Inventory',
    defaultPermissions: [
      'dashboard.view',
      'calendar.view',
      'calendar.manage_blocks',
      'bookings.view',
      'bookings.create',
      'bookings.approve',
      'bookings.check_in_out',
      'payments.view',
      'housekeeping.manage',
      'transfers.manage',
      'maintenance.manage',
      'messages.manage',
      'reports.view',
      'view_dashboard',
      'view_calendar',
      'manage_room_blocks',
      'view_bookings',
      'manage_bookings',
      'check_in_out',
      'view_payments',
      'view_housekeeping',
      'manage_housekeeping',
      'view_transfers',
      'update_transfer_status',
      'view_maintenance',
      'manage_maintenance',
      'view_guest_requests',
      'manage_guest_requests',
      'view_reports',
    ],
  ),
  sales(
    key: 'sales',
    label: 'Sales & Reservations',
    department: 'Reservations & Corporate Sales',
    defaultPermissions: [
      'dashboard.view',
      'calendar.view',
      'calendar.manage_blocks',
      'bookings.view',
      'bookings.create',
      'bookings.approve',
      'pricing.manage',
      'messages.manage',
      'reports.view',
      'view_dashboard',
      'view_calendar',
      'manage_room_blocks',
      'view_bookings',
      'manage_bookings',
      'manage_rates',
      'view_guest_requests',
      'manage_guest_requests',
      'view_reports',
    ],
  ),
  frontDesk(
    key: 'front_desk',
    label: 'Front Desk Officer',
    department: 'Front Office & Guest Relations',
    defaultPermissions: [
      'dashboard.view',
      'calendar.view',
      'bookings.view',
      'bookings.create',
      'bookings.check_in_out',
      'payments.view',
      'transfers.manage',
      'messages.manage',
      'view_dashboard',
      'view_calendar',
      'view_bookings',
      'manage_bookings',
      'check_in_out',
      'view_payments',
      'view_transfers',
      'update_transfer_status',
      'view_guest_requests',
      'manage_guest_requests',
    ],
  ),
  accounts(
    key: 'accounts',
    label: 'Accounts & Finance',
    department: 'Finance & Accounts',
    defaultPermissions: [
      'dashboard.view',
      'bookings.view',
      'payments.view',
      'payments.verify',
      'refunds.approve',
      'reports.view',
      'view_dashboard',
      'view_bookings',
      'view_payments',
      'verify_payments',
      'manage_folio',
      'generate_invoices',
      'approve_refund',
      'process_refund',
      'view_reports',
    ],
  ),
  housekeeping(
    key: 'housekeeping',
    label: 'Housekeeping Staff',
    department: 'Housekeeping & Room Readiness',
    defaultPermissions: [
      'dashboard.view',
      'housekeeping.manage',
      'maintenance.manage',
      'view_dashboard',
      'view_housekeeping',
      'manage_housekeeping',
      'view_maintenance',
    ],
  ),
  driver(
    key: 'driver',
    label: 'Driver / Transport',
    department: 'Airport & Estate Transfers',
    defaultPermissions: [
      'dashboard.view',
      'transfers.manage',
      'view_dashboard',
      'view_transfers',
      'update_transfer_status',
    ],
  ),
  maintenance(
    key: 'maintenance',
    label: 'Maintenance Technician',
    department: 'Facilities & Engineering',
    defaultPermissions: [
      'dashboard.view',
      'maintenance.manage',
      'view_dashboard',
      'view_maintenance',
      'manage_maintenance',
    ],
  );

  final String key;
  final String label;
  final String department;
  final List<String> defaultPermissions;

  const StaffRole({
    required this.key,
    required this.label,
    required this.department,
    required this.defaultPermissions,
  });

  bool hasPermission(String permissionKey) {
    if (defaultPermissions.contains('*')) return true;
    return defaultPermissions.contains(permissionKey);
  }

  static StaffRole fromKey(String key) {
    return StaffRole.values.firstWhere(
      (r) => r.key == key,
      orElse: () => StaffRole.frontDesk,
    );
  }
}

class StaffMemberModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final StaffRole role;
  final String? assignedEstate;
  final bool isActive;
  final String invitationStatus; // 'active', 'pending_invitation', 'expired'
  final DateTime? invitationExpiresAt;
  final DateTime? lastLoginAt;
  final List<String> effectivePermissions;

  const StaffMemberModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.assignedEstate,
    this.isActive = true,
    this.invitationStatus = 'active',
    this.invitationExpiresAt,
    this.lastLoginAt,
    required this.effectivePermissions,
  });

  bool can(String permission) => hasPermission(permission);

  bool hasPermission(String permission) {
    if (role == StaffRole.owner || effectivePermissions.contains('*')) {
      return true;
    }
    if (effectivePermissions.contains(permission)) return true;
    return role.hasPermission(permission);
  }
}
