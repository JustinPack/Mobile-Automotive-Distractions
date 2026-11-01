package mad.mp;

import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;
import se.krka.kahlua.integration.annotations.LuaMethod;

/** Prototype only. The server must first grant and later revoke vehicle authority. */
public final class ClientLease {
    private record Lease(long expires, int owner, int direction, float steering, float target, boolean brake) {}
    private static final Map<Object, Lease> leases = Collections.synchronizedMap(new WeakHashMap<>());
    private static Object call(Object target, String name) throws ReflectiveOperationException {
        return target.getClass().getMethod(name).invoke(target);
    }
    private static boolean eligible(Object vehicle, int playerId) throws ReflectiveOperationException {
        return Class.forName("zombie.network.GameClient").getField("client").getBoolean(null)
            && !Class.forName("zombie.network.GameServer").getField("server").getBoolean(null)
            && vehicle != null && playerId >= 0
            && ((Number)call(vehicle, "getNetPlayerId")).intValue() == playerId
            && Boolean.TRUE.equals(call(vehicle, "isLocalPhysicSim"))
            && call(vehicle, "getDriver") == null
            && Boolean.TRUE.equals(call(vehicle, "isEngineRunning"));
    }
    @LuaMethod(name="MADMPStartClientLeaseTest", global=true)
    public static boolean start(Object vehicle, double playerId) {
        try {
            if (!Double.isFinite(playerId) || playerId != Math.floor(playerId) || playerId > Short.MAX_VALUE
                || !eligible(vehicle, (int)playerId)) return false;
            leases.put(vehicle, new Lease(System.nanoTime() + 12_000_000_000L, (int)playerId, 1, 0, 10, false));
            return true;
        } catch (Throwable e) { System.err.println("[MAD MP] Client lease rejected: " + e); return false; }
    }
    /** Renewable short lease for an integrated rig; no persistent input on disconnect. */
    @LuaMethod(name="MADMPSetRigInput", global=true)
    public static boolean setRigInput(Object vehicle, double playerId, double direction, double steering, double target, boolean brake) {
        try {
            if (!Double.isFinite(playerId) || playerId!=Math.floor(playerId) || playerId<0 || playerId>Short.MAX_VALUE
                || (direction!=1 && direction!=-1) || !Double.isFinite(steering) || Math.abs(steering)>1
                || !Double.isFinite(target) || target<=0 || target>50 || !eligible(vehicle,(int)playerId)) return false;
            leases.put(vehicle,new Lease(System.nanoTime()+3_000_000_000L,(int)playerId,(int)direction,(float)steering,(float)target,brake));
            return true;
        } catch (Throwable e) { System.err.println("[MAD MP] Rig input rejected: "+e); return false; }
    }
    @LuaMethod(name="MADMPStopClientLeaseTest", global=true)
    public static boolean stop(Object vehicle) {
        if (vehicle == null || leases.remove(vehicle) == null) return false;
        try { clear(call(call(vehicle, "getController"), "getClientControls")); }
        catch (Throwable e) { System.err.println("[MAD MP] Client cleanup failed: " + e); }
        return true;
    }
    public static void onUpdate(Object controller) {
        try {
            Object vehicle=controller.getClass().getField("vehicleObject").get(controller);
            Lease lease=leases.get(vehicle);
            if (lease==null) return;
            if (System.nanoTime()-lease.expires()>=0 || !eligible(vehicle,lease.owner())) { stop(vehicle); return; }
            Object input=call(controller,"getClientControls");
            float speed=Math.abs(((Number)call(vehicle,"getCurrentSpeedKmHour")).floatValue());
            boolean accelerate=!lease.brake() && speed<lease.target();
            input.getClass().getField("forward").setBoolean(input,accelerate && lease.direction()==1);
            input.getClass().getField("backward").setBoolean(input,accelerate && lease.direction()==-1);
            input.getClass().getField("brake").setBoolean(input,lease.brake());
            input.getClass().getField("steering").setFloat(input,lease.steering());
        } catch (Throwable e) { System.err.println("[MAD MP] Client lease failed: " + e); }
    }
    public static boolean suppressPark(Object controller) {
        try {
            Object vehicle=controller.getClass().getField("vehicleObject").get(controller);
            Lease lease=leases.get(vehicle);
            return lease!=null && System.nanoTime()-lease.expires()<0 && eligible(vehicle,lease.owner());
        } catch (Throwable e) { return false; }
    }
    public static boolean allowEmptyPassengerMap(Object vehicle) {
        try {
            Lease lease=leases.get(vehicle);
            if (lease==null || System.nanoTime()-lease.expires()>=0 || !eligible(vehicle,lease.owner())) return false;
            int count=((Number)call(vehicle,"getMaxPassengers")).intValue();
            for (int i=0;i<count;i++) if (vehicle.getClass().getMethod("getCharacter",int.class).invoke(vehicle,i)!=null) return false;
            return true;
        } catch (Throwable e) { return false; }
    }
    @LuaMethod(name="MADMPClientDiagnostics", global=true)
    public static String diagnostics(Object vehicle) {
        try {
            Object controller=call(vehicle,"getController");
            Object controls=call(controller,"getClientControls");
            return "gas="+call(controller,"isGas")+" forward="+controls.getClass().getField("forward").getBoolean(controls)
                +" backward="+controls.getClass().getField("backward").getBoolean(controls)
                +" brakeInput="+controls.getClass().getField("brake").getBoolean(controls)
                +" shift="+controls.getClass().getField("shift").getBoolean(controls)
                +" invalidAhead="+call(vehicle,"isInvalidChunkAhead")
                +" force="+controller.getClass().getField("engineForce").getFloat(controller)
                +" brake="+controller.getClass().getField("brakingForce").getFloat(controller)
                +" speed="+call(vehicle,"getCurrentSpeedKmHour")+" leaseActive="+suppressPark(controller);
        } catch (Throwable e) { return "diagnostics unavailable: "+e; }
    }
    private static void clear(Object input) throws ReflectiveOperationException {
        input.getClass().getField("forward").setBoolean(input,false);
        input.getClass().getField("backward").setBoolean(input,false);
        input.getClass().getField("brake").setBoolean(input,false);
        input.getClass().getField("steering").setFloat(input,0);
    }
}
