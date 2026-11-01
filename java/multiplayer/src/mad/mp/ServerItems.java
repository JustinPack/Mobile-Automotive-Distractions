package mad.mp;
import java.nio.ByteBuffer;
import java.util.Base64;
import java.util.ArrayList;
import java.util.Collection;
import se.krka.kahlua.integration.annotations.LuaMethod;

/** Item snapshots for server-owned rig attachments. */
public final class ServerItems {
    private static boolean server() throws Exception {
        return Class.forName("zombie.network.GameServer").getField("server").getBoolean(null)
            && !Class.forName("zombie.network.GameClient").getField("client").getBoolean(null);
    }
    @LuaMethod(name="MADMPLoadedVehicles",global=true)
    public static Object loadedVehicles(Object cell) {
        try {
            if (!server() || cell==null) return null;
            Object vehicles=cell.getClass().getMethod("getVehicles").invoke(cell);
            return vehicles instanceof Collection<?> c ? new ArrayList<>(c) : null;
        } catch (Throwable e) { System.err.println("[MAD MP] Vehicle lookup failed: "+e); return null; }
    }
    @LuaMethod(name="MADMPSaveItem",global=true)
    public static String save(Object item) {
        try {
            Class<?> type=Class.forName("zombie.inventory.InventoryItem");
            if (!server() || !type.isInstance(item)) return null;
            ByteBuffer buffer=ByteBuffer.allocate(24000);
            type.getMethod("saveWithSize",ByteBuffer.class,boolean.class).invoke(item,buffer,false);
            byte[] bytes=new byte[buffer.position()]; buffer.flip(); buffer.get(bytes);
            int version=((Number)Class.forName("zombie.iso.IsoWorld").getMethod("getWorldVersion").invoke(null)).intValue();
            return version+":"+Base64.getEncoder().encodeToString(bytes);
        } catch (Throwable e) { System.err.println("[MAD MP] Item snapshot failed: "+e); return null; }
    }
    @LuaMethod(name="MADMPLoadItem",global=true)
    public static Object load(String snapshot) {
        try {
            if (!server() || snapshot==null || snapshot.length()>40000) return null;
            int split=snapshot.indexOf(':'); if (split<1) return null;
            int version=Integer.parseInt(snapshot.substring(0,split));
            return Class.forName("zombie.inventory.InventoryItem").getMethod("loadItem",ByteBuffer.class,int.class)
                .invoke(null,ByteBuffer.wrap(Base64.getDecoder().decode(snapshot.substring(split+1))),version);
        } catch (Throwable e) { System.err.println("[MAD MP] Item recovery failed: "+e); return null; }
    }
}
