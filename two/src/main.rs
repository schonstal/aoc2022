use std::fs;
use std::collections::BinaryHeap;

fn main() {
    let file_contents = fs::read_to_string("list.txt").expect("failed to read list.txt");
    let lines = file_contents.split("\n");

    let mut current = 0;
    let mut results = BinaryHeap::new(); 

    for line in lines {
        match line.parse::<i32>() {
            Ok(value) => current += value,
            Err(_) => {
                results.push(current);
                current = 0;
            }
        }

    }
    
    let mut sum = 0;
    for _ in 0..3 {
        let value = results.pop().unwrap();
        sum += value;
        println!("{:?}", value);
    }

    println!("sum: {:?}", sum);
}
