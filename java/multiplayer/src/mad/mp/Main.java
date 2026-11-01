package mad.mp;

import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;
import java.util.concurrent.atomic.AtomicInteger;
import net.bytebuddy.jar.asm.ClassReader;
import net.bytebuddy.jar.asm.ClassVisitor;
import net.bytebuddy.jar.asm.ClassWriter;
import net.bytebuddy.jar.asm.MethodVisitor;
import net.bytebuddy.jar.asm.Opcodes;

/** Replace one UI-only call inside the server's vanilla vehicle controller. */
public final class Main {
    public static byte[] transformController(byte[] bytes) {
        AtomicInteger matches = new AtomicInteger();
        ClassReader reader = new ClassReader(bytes);
        ClassWriter writer = new ClassWriter(reader, 0);
        reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
            @Override public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {
                MethodVisitor original = super.visitMethod(access, name, desc, signature, exceptions);
                if (!name.equals("update") || !desc.equals("()V")) return original;
                return new MethodVisitor(Opcodes.ASM9, original) {
                    @Override public void visitMethodInsn(int opcode, String owner, String method, String descriptor, boolean itf) {
                        if (opcode == Opcodes.INVOKEVIRTUAL && owner.equals("zombie/ui/SpeedControls")
                            && method.equals("SetCurrentGameSpeed") && descriptor.equals("(I)V")) {
                            matches.incrementAndGet();
                            super.visitMethodInsn(Opcodes.INVOKESTATIC, "mad/mp/HeadlessSpeed", "setSpeed", "(Lzombie/ui/SpeedControls;I)V", false);
                        } else super.visitMethodInsn(opcode, owner, method, descriptor, itf);
                    }
                };
            }
        }, 0);
        if (matches.get() != 1) throw new IllegalStateException("Expected one speed-control call, found " + matches.get());
        return writer.toByteArray();
    }
    public static void main(String[] args) {
        try {
            if (!Class.forName("zombie.network.GameServer").getField("server").getBoolean(null)) return;
            java.lang.reflect.Field field = Class.forName("me.zed_0xff.zombie_buddy.Loader").getDeclaredField("g_instrumentation");
            field.setAccessible(true);
            Instrumentation instrumentation = (Instrumentation) field.get(null);
            instrumentation.addTransformer(new ClassFileTransformer() {
                @Override public byte[] transform(ClassLoader loader, String name, Class<?> type, ProtectionDomain domain, byte[] bytes) {
                    if (!"zombie/core/physics/CarController".equals(name)) return null;
                    try {
                        byte[] result=transformController(bytes);
                        System.out.println("[MAD MP] Headless speed-control call patched.");
                        return result;
                    } catch (Throwable e) { System.err.println("[MAD MP] Headless patch failed: " + e); return null; }
                }
            }, true);
            for (Class<?> type : instrumentation.getAllLoadedClasses()) {
                if (type.getName().equals("zombie.core.physics.CarController")) instrumentation.retransformClasses(type);
            }
            System.out.println("[MAD MP] Headless controller transformer installed.");
        } catch (Throwable e) { System.err.println("[MAD MP] Could not install headless controller transformer: " + e); }
    }
}
