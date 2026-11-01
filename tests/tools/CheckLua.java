import java.nio.file.*;
import java.lang.reflect.*;
public class CheckLua {
 public static void main(String[] args) throws Exception {
  Class<?> plat=Class.forName("se.krka.kahlua.vm.Platform"), table=Class.forName("se.krka.kahlua.vm.KahluaTable");
  Object p=Class.forName("se.krka.kahlua.j2se.J2SEPlatform").getConstructor().newInstance(), env=p.getClass().getMethod("newEnvironment").invoke(p);
  Class<?> thread=Class.forName("se.krka.kahlua.vm.KahluaThread"); Object t=thread.getConstructor(plat,table).newInstance(p,env); thread.getField("debugOwnerThread").set(t, Thread.currentThread());
  Method load=Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler").getMethod("loadstring",String.class,String.class,table), call=thread.getMethod("call",Object.class,Object[].class);
  for(String f:args){Object c=load.invoke(null,Files.readString(Path.of(f)),f,env); call.invoke(t,c,new Object[0]); System.out.println("OK " + f);}
 }
}

