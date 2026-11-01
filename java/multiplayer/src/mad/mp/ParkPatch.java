package mad.mp;
import me.zed_0xff.zombie_buddy.Patch;
@Patch(className="zombie.core.physics.CarController", methodName="park", warmUp=true, strictMatch=true)
public final class ParkPatch {
    @Patch.OnEnter(skipOn=true)
    public static boolean enter(@Patch.This Object controller) { return false; }
}
