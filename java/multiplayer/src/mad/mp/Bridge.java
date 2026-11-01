package mad.mp;

import se.krka.kahlua.integration.annotations.LuaMethod;
import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;

/** Server-only, expiring input experiment; never accepts parameters from clients. */
public final class Bridge {
    private static final Map<Object, Long> ACTIVE = Collections.synchronizedMap(new WeakHashMap<>());
    private static Object call(Object value, String method) throws ReflectiveOperationException {
        return value.getClass().getMethod(method).invoke(value);
    }
    private static boolean allowed(Object vehicle) throws ReflectiveOperationException {
        return Class.forName("zombie.network.GameServer").getField("server").getBoolean(null)
            && !Class.forName("zombie.network.GameClient").getField("client").getBoolean(null)
            && vehicle != null && Boolean.TRUE.equals(call(vehicle, "isLocalPhysicSim"))
            && call(vehicle, "getDriver") == null && Boolean.TRUE.equals(call(vehicle, "isEngineRunning"))
            && call(vehicle, "getController") != null;
    }
    @LuaMethod(name="MADMPStartForwardTest", global=true)
    public static boolean start(Object vehicle) {
        try {
            if (!allowed(vehicle)) return false;
            ACTIVE.put(vehicle, System.nanoTime() + 3_000_000_000L);
            return true;
        } catch (Throwable e) { System.err.println("[MAD MP] Test rejected: " + e); return false; }
    }
    @LuaMethod(name="MADMPStopForwardTest", global=true)
    public static boolean stop(Object vehicle) {
        if (vehicle == null || ACTIVE.remove(vehicle) == null) return false;
        try { clear(call(vehicle, "getController")); }
        catch (Throwable e) { System.err.println("[MAD MP] Input cleanup failed: " + e); }
        return true;
    }
    public static void onUpdate(Object controller) {
        try {
            Object vehicle = controller.getClass().getField("vehicleObject").get(controller);
            Long expiry = ACTIVE.get(vehicle);
            if (expiry == null) return;
            if (System.nanoTime() - expiry >= 0 || !allowed(vehicle)) { stop(vehicle); return; }
            Object input = call(controller, "getClientControls");
            float speed = Math.abs(((Number) call(vehicle, "getCurrentSpeedKmHour")).floatValue());
            input.getClass().getField("forward").setBoolean(input, speed < 10);
            input.getClass().getField("backward").setBoolean(input, false);
            input.getClass().getField("brake").setBoolean(input, false);
            input.getClass().getField("steering").setFloat(input, 0);
        } catch (Throwable e) { System.err.println("[MAD MP] Input hook failed: " + e); }
    }
    private static void clear(Object controller) throws ReflectiveOperationException {
        Object input = call(controller, "getClientControls");
        input.getClass().getField("forward").setBoolean(input, false);
        input.getClass().getField("backward").setBoolean(input, false);
        input.getClass().getField("brake").setBoolean(input, false);
        input.getClass().getField("steering").setFloat(input, 0);
    }
}
