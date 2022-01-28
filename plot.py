import matplotlib.pyplot as plt

file = "i_file"
x_list = list()
y_list = list()
with open(file, "r") as file:
    i = 0
    for line in file:
        if i % 60 == 0:
            print(i)
            print("hello")
            x, y = line.split(",") # could cause errors if there are mor than one comma
            x_list.append(x)
            y_list.append(y)
        i += 1

print(len(x_list))
plt.plot(x_list, y_list)
plt.show()
