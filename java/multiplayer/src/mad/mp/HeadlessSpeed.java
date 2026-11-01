package mad.mp;
import zombie.ui.SpeedControls;

/** Preserve vanilla behavior when the UI exists; a headless server has no UI. */
public final class HeadlessSpeed {
    public static void setSpeed(SpeedControls controls, int speed) {
        if (controls != null) controls.SetCurrentGameSpeed(speed);
    }
}
