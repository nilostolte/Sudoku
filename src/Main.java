public class Main {
    public static void main(String[] args) {
        char[][] g = {
                {8,0,0,0,0,0,0,0,0},
                {0,0,3,6,0,0,0,0,0},
                {0,7,0,0,9,0,2,0,0},
                {0,5,0,0,0,7,0,0,0},
                {0,0,0,0,4,5,7,0,0},
                {0,0,0,1,0,0,0,3,0},
                {0,0,1,0,0,0,0,6,8},
                {0,0,8,5,0,0,0,1,0},
                {0,9,0,0,0,0,4,0,0},
        };
        Grid grid = new Grid();
        // grid initialized with the matrix supplied in the code above
        grid.init(g);
        //grid.generate_table();
        long init = System.nanoTime();
        grid.solve();
        System.out.println(System.nanoTime()-init);
        grid.print();
        // grid initialized with a line by line linear string
        Grid.set(g,"080000000205003600300820700000600001004138500900007000002065009001700205000000040");
        grid.reinit(g);
        init = System.nanoTime();
        grid.solve();
        System.out.println(System.nanoTime()-init);
        grid.print();
        // grid initialized with a line by line linear string, where periods are zeros
        Grid.set(g,"4.27.6...........656..1..7.....5.21.1.......8.87.9.....3..7..658...........9.84.1".replace('.','0'));
        grid.reinit(g);
        init = System.nanoTime();
        grid.solve();
        System.out.println(System.nanoTime()-init);
        grid.print();
    }
}