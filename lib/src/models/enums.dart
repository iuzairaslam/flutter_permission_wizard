/// Visual presentation styles for the rationale (pre-OS-request) UI.
///
/// The package will render the same content described in
/// [PermissionRationale] using one of these layouts:
///
/// * [RationaleStyle.dialog] — a centered modal `AlertDialog` (default).
/// * [RationaleStyle.bottomSheet] — a `DraggableScrollableSheet` attached to
///   the bottom edge.
/// * [RationaleStyle.fullScreen] — a full-screen route pushed onto the
///   navigator.
enum RationaleStyle { dialog, bottomSheet, fullScreen }

/// Visual presentation styles for the denied / permanently-denied UI.
enum DeniedStyle { dialog, bottomSheet, fullScreen }

/// Strategy for [BatchPermissionRequest].
///
/// * [BatchStrategy.combined] — show one shared rationale (listing every
///   permission via bullets) and then sequentially request each permission
///   from the OS without any further rationale UI.
/// * [BatchStrategy.sequential] — run a full wizard flow per permission,
///   showing each permission's own rationale, denial, and settings UI before
///   moving on to the next.
enum BatchStrategy { combined, sequential }
