package mad.mp;
import me.zed_0xff.zombie_buddy.Patch;

/** A leased empty vehicle has no passengers whose chunk maps need checking. */
@Patch(className="zombie.network.PassengerMap", methodName="isChunkLoaded", warmUp=true, strictMatch=true)
public final class PassengerMapPatch {
    @Patch.OnExit
    public static void exit(@Patch.Argument(0) Object vehicle, @Patch.Return(readOnly=false) boolean loaded) {
        if (ClientLease.allowEmptyPassengerMap(vehicle)) loaded=true;
    }
}
