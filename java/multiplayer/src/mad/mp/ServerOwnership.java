package mad.mp;

import se.krka.kahlua.integration.annotations.LuaMethod;

/** Experimental bounded vehicle authority handoff; never steals existing ownership. */
public final class ServerOwnership {
    private static Object call(Object o, String name) throws ReflectiveOperationException {
        return o.getClass().getMethod(name).invoke(o);
    }
    private static boolean server() throws ReflectiveOperationException {
        return Class.forName("zombie.network.GameServer").getField("server").getBoolean(null)
            && !Class.forName("zombie.network.GameClient").getField("client").getBoolean(null);
    }
    private static void mark(Object vehicle) throws ReflectiveOperationException {
        var flags=vehicle.getClass().getField("updateFlags");
        flags.setShort(vehicle, (short)(flags.getShort(vehicle) | 8192));
    }
    private static void changeOwner(Object vehicle, Object player) throws ReflectiveOperationException {
        for (var method : vehicle.getClass().getMethods()) {
            if (method.getName().equals("authorizationChanged") && method.getParameterCount()==1) {
                method.invoke(vehicle,player);
                return;
            }
        }
        throw new NoSuchMethodException("authorizationChanged");
    }
    @LuaMethod(name="MADMPGrantClientTest", global=true)
    public static boolean grant(Object vehicle, Object player) {
        try {
            if (!server() || vehicle==null || player==null || call(vehicle,"getDriver")!=null
                || !Boolean.TRUE.equals(call(vehicle,"isEngineRunning")) || !Boolean.TRUE.equals(call(vehicle,"isStopped"))
                || ((Number)call(vehicle,"getNetPlayerId")).intValue()!=-1
                || call(vehicle,"getVehicleTowing")!=null || call(vehicle,"getVehicleTowedBy")!=null) return false;
            int id=((Number)call(player,"getOnlineID")).intValue();
            if (id<0 || id>Short.MAX_VALUE) return false;
            changeOwner(vehicle,player);
            if (((Number)call(vehicle,"getNetPlayerId")).intValue()!=id) return false;
            mark(vehicle);
            return true;
        } catch (Throwable e) { System.err.println("[MAD MP] Grant failed: " + e); return false; }
    }
    @LuaMethod(name="MADMPRevokeClientTest", global=true)
    public static boolean revoke(Object vehicle, Object player) {
        try {
            if (!server() || vehicle==null || player==null || call(vehicle,"getDriver")!=null) return false;
            int id=((Number)call(player,"getOnlineID")).intValue();
            if (id<0 || ((Number)call(vehicle,"getNetPlayerId")).intValue()!=id) return false;
            changeOwner(vehicle,null);
            mark(vehicle);
            return true;
        } catch (Throwable e) { System.err.println("[MAD MP] Revoke failed: " + e); return false; }
    }
    @LuaMethod(name="MADMPRevokeOrphan", global=true)
    public static boolean revokeOrphan(Object vehicle, double ownerId) {
        try {
            if (!server() || vehicle==null || call(vehicle,"getDriver")!=null || !Double.isFinite(ownerId)
                || ownerId<0 || ownerId>Short.MAX_VALUE || ownerId!=Math.floor(ownerId)
                || ((Number)call(vehicle,"getNetPlayerId")).intValue()!=(int)ownerId) return false;
            changeOwner(vehicle,null); mark(vehicle); return true;
        } catch (Throwable e) { System.err.println("[MAD MP] Orphan release failed: "+e); return false; }
    }
}
