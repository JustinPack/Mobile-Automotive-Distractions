package mad.rig;
import me.zed_0xff.zombie_buddy.Patch;
@Patch(className="zombie.core.physics.CarController", methodName="update", warmUp=true, strictMatch=true)
public class VehiclePatch {
    @Patch.OnEnter
    public static void enter(@Patch.This Object controller) {
        Bridge.onUpdate(controller);
    }
}

