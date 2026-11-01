package mad.rig;
import se.krka.kahlua.integration.annotations.LuaMethod;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.util.Base64;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;

/** Experimental input bridge. Multiplayer is intentionally prohibited. */
public final class Bridge {
    private static final Map<Object, Input> INPUTS = Collections.synchronizedMap(new WeakHashMap<>());
    private static final class Input {
        final int direction; final float steering; final float speed; final boolean brake; final long expiresAt;
        Input(int direction, float steering, float speed, boolean brake) {
            this.direction = direction; this.steering = steering; this.speed = speed; this.brake = brake;
            this.expiresAt = System.nanoTime() + 3_000_000_000L;
        }
    }
    /** Serialize a real inventory item before detaching it. Null means no transfer. */
    @LuaMethod(name="MADPackItem", global=true)
    public static String packItem(Object item) {
        try {
            if (!standalone() || item == null) return null;
            Class<?> itemClass = Class.forName("zombie.inventory.InventoryItem");
            if (!itemClass.isInstance(item)) return null;
            ByteBuffer buffer = ByteBuffer.allocate(24000);
            itemClass.getMethod("saveWithSize", ByteBuffer.class, boolean.class).invoke(item, buffer, false);
            byte[] bytes = new byte[buffer.position()];
            buffer.flip(); buffer.get(bytes);
            int version = ((Number) Class.forName("zombie.iso.IsoWorld").getMethod("getWorldVersion").invoke(null)).intValue();
            return version + ":" + Base64.getEncoder().encodeToString(bytes);
        } catch (Throwable e) { System.err.println("[MAD] Item serialization failed: " + e); return null; }
    }
    /** Recreate the exact serialized item; callers must only consume the blob once. */
    @LuaMethod(name="MADUnpackItem", global=true)
    public static Object unpackItem(String encoded) {
        try {
            if (!standalone() || encoded == null || encoded.length() > 40000) return null;
            int split = encoded.indexOf(':');
            if (split < 1) return null;
            int version = Integer.parseInt(encoded.substring(0, split));
            byte[] bytes = Base64.getDecoder().decode(encoded.substring(split + 1));
            return Class.forName("zombie.inventory.InventoryItem").getMethod("loadItem", ByteBuffer.class, int.class)
                    .invoke(null, ByteBuffer.wrap(bytes), version);
        } catch (Throwable e) { System.err.println("[MAD] Item deserialization failed: " + e); return null; }
    }
    @LuaMethod(name="MADLoadedVehicles", global=true)
    public static Object loadedVehicles(Object cell) {
        try {
            if (!standalone() || cell == null) return null;
            Object vehicles = cell.getClass().getMethod("getVehicles").invoke(cell);
            if (!(vehicles instanceof Collection<?>)) return null;
            return new ArrayList<>((Collection<?>) vehicles);
        } catch (Throwable e) { System.err.println("[MAD] Vehicle lookup failed: " + e); return null; }
    }
    private static boolean standalone() throws ReflectiveOperationException {
        return !Class.forName("zombie.network.GameClient").getField("client").getBoolean(null)
            && !Class.forName("zombie.network.GameServer").getField("server").getBoolean(null);
    }
    private static Object invoke(Object object, String name) throws ReflectiveOperationException {
        return object.getClass().getMethod(name).invoke(object);
    }
    @LuaMethod(name="MADSetRigControls", global=true)
    public static boolean setTestControls(Object vehicle, double direction, double steering, double speed, boolean brake) {
        try {
            if (!standalone() || vehicle == null || (direction != -1 && direction != 0 && direction != 1)
                    || !Double.isFinite(steering) || Math.abs(steering) > 1
                    || !Double.isFinite(speed) || speed <= 0 || speed > 50
                    || invoke(vehicle, "getDriver") != null || !Boolean.TRUE.equals(invoke(vehicle, "isEngineRunning"))
                    || invoke(vehicle, "getController") == null) return false;
            INPUTS.put(vehicle, new Input((int) direction, (float) steering, (float) speed, brake));
            return true;
        } catch (Throwable e) { System.err.println("[MAD agent] test request rejected: " + e); return false; }
    }
    @LuaMethod(name="MADClearRigControls", global=true)
    public static boolean clearTestControls(Object vehicle) {
        if (vehicle == null) return false;
        boolean removed = INPUTS.remove(vehicle) != null;
        if (removed) {
            try { clearInputs(invoke(vehicle, "getController")); }
            catch (Throwable e) { System.err.println("[MAD agent] failed to clear controls: " + e); }
        }
        return removed;
    }
    public static void onUpdate(Object controller) {
        try {
            if (!standalone()) return;
            Object vehicle = controller.getClass().getField("vehicleObject").get(controller);
            Input input = INPUTS.get(vehicle);
            if (input == null) return;
            if (System.nanoTime() - input.expiresAt >= 0 || invoke(vehicle, "getDriver") != null
                    || !Boolean.TRUE.equals(invoke(vehicle, "isEngineRunning"))) {
                INPUTS.remove(vehicle);
                clearInputs(controller);
                return;
            }
            Object controls = invoke(controller, "getClientControls");
            float actual = Math.abs(((Number) invoke(vehicle, "getCurrentSpeedKmHour")).floatValue());
            boolean accelerate = !input.brake && actual < input.speed;
            setBoolean(controls, "forward", accelerate && input.direction > 0);
            setBoolean(controls, "backward", accelerate && input.direction < 0);
            setBoolean(controls, "brake", input.brake);
            controls.getClass().getField("steering").setFloat(controls, input.steering);
        } catch (Throwable e) { System.err.println("[MAD agent] control hook failed: " + e); }
    }
    private static void clearInputs(Object controller) throws ReflectiveOperationException {
        Object c = invoke(controller, "getClientControls");
        setBoolean(c, "forward", false); setBoolean(c, "backward", false); setBoolean(c, "brake", false);
        c.getClass().getField("steering").setFloat(c, 0);
    }
    private static void setBoolean(Object object, String field, boolean value) throws ReflectiveOperationException {
        object.getClass().getField(field).setBoolean(object, value);
    }
}







